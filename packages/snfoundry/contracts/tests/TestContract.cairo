// import libraries
use contracts::counter::{
    Counter, ICounterDispatcher, ICounterDispatcherTrait, ICounterSafeDispatcher,
    ICounterSafeDispatcherTrait,
};
use openzeppelin_access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use snforge_std::EventSpyAssertionsTrait;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, spy_events, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress};

const ZERO_COUNT: u32 = 0;

// Test Accounts
fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

fn USER_1() -> ContractAddress {
    'USER_1'.try_into().unwrap()
}


// util deploy function
fn __deploy__(init_value: u32) -> (ICounterDispatcher, IOwnableDispatcher, ICounterSafeDispatcher) {
    // declare contract
    let contract_class = declare("Counter").expect('failed to declare').contract_class();

    // serialize constructor args
    let mut calldata: Array<felt252> = array![];
    init_value.serialize(ref calldata);
    OWNER().serialize(ref calldata);

    // deploy contract
    let (contract_address, _) = contract_class.deploy(@calldata).expect('failed to deploy');

    // return values
    let counter = ICounterDispatcher { contract_address };
    let ownable = IOwnableDispatcher { contract_address };
    let safe_dispatcher = ICounterSafeDispatcher { contract_address };
    (counter, ownable, safe_dispatcher)
}

#[test]
fn test_counter_deployment() {
    let (counter, ownable, _) = __deploy__(ZERO_COUNT);
    // get current count
    let count_1 = counter.get_counter();

   
    assert(count_1 == ZERO_COUNT, 'count not set');  // Verify that the counter value is by exactly 0.
    assert(ownable.owner() == OWNER(), 'owner not set');  // Verify that the counter contract owner matches our Test Owner account
}

#[test]
fn test_increase_counter() {
    let (counter, _, _) = __deploy__(ZERO_COUNT);
    // get current count
    let count_1 = counter.get_counter();

    // assertions
    assert(count_1 == ZERO_COUNT, 'count not set');

    // state-changing txn
    counter.increase_counter();

    // retrieve current count
    let count_2 = counter.get_counter();

    // assert that count increased by 1
    assert(count_2 == count_1 + 1, 'invalid count');
}


#[test]
fn test_emitted_increased_event() {
    // Deploy the `counter` contract starting from ZERO_COUNT (usually 0).
    let (counter, _, _) = __deploy__(ZERO_COUNT);

    // Create a spy instance to capture and inspect emitted events during the test.
    let mut spy = spy_events();

    // Simulate a transaction coming from USER_1 by setting them as the caller.
    start_cheat_caller_address(counter.contract_address, USER_1());

    // Call the `increase_counter` function — this should emit an `Increased` event.
    counter.increase_counter();

    // Stop mocking the caller address to clean up the test context.
    stop_cheat_caller_address(counter.contract_address);

    // Check that the correct `Increased` event was emitted, tied to USER_1's address.
    spy
        .assert_emitted(
            @array![
                (
                    counter.contract_address,
                    Counter::Event::Increased(Counter::Increased { account: USER_1() }),
                ),
            ],
        );

    // Also verify that no `Decreased` event was accidentally emitted.
    // This ensures only the intended event occurred during the increase_counter txn.
    spy
        .assert_not_emitted(
            @array![
                (
                    counter.contract_address,
                    Counter::Event::Decreased(Counter::Decreased { account: USER_1() }),
                ),
            ],
        )
}


#[test]
#[feature("safe_dispatcher")]
fn test_safe_panic_decrease_counter() {
    // Deploy a new instance of the `counter` contract starting at 0,
    // and retrieve the `safe_dispatcher`, which enables safe function calls to handle error gracefully.
    let (counter, _, safe_dispatcher) = __deploy__(ZERO_COUNT);

    // Ensure the counter is initialized correctly to 0 before proceeding.
    assert(counter.get_counter() == ZERO_COUNT, 'invalid count');

    // Use the safe dispatcher to attempt decreasing the counter.
    // Since the counter is already zero, this should fail.
    match safe_dispatcher.decrease_counter() {
        // If the decrease_counter perhaps succeeds in any way, fail the test with a panic.
        Result::Ok(_) => panic!("cannot decrease 0"),

        // If it fails (as expected), check that the error message is correct.
        // Note: `e` is an array of error messages.
        // We access the first error using either `*e[0]` or `*e.at(0)`.
        // Both are valid and give the value at index 0 — because we're interested in the first error message.
        Result::Err(e) => assert(*e[0] == 'Decreasing Empty counter', *e.at(0)),
    }
}

#[test]
#[should_panic(
    expected: 'Decreasing Empty counter',
)] // This attribute marks the test as *expected to panic*.
fn test_panic_decrease_counter() {
    // Deploy the `counter` contract initialized at ZERO_COUNT
    let (counter, _, _) = __deploy__(ZERO_COUNT);

    // Confirm that the counter starts at 0 to ensure we're testing the edge case correctly.
    assert(counter.get_counter() == ZERO_COUNT, 'invalid count');

    // Attempt to decrease the counter while it's already at zero.
    // This should trigger a panic, and the test will pass *only if* the panic message matches
    // the expected string: 'Decreasing Empty counter'.
    counter.decrease_counter()
}


#[test]
fn test_successful_decrease_counter() {
    // Deploy a `counter` contract instance, starting with an initial count of 5.
    // We ignore the other returned values (like owner and dispatcher) since we don't need them for
    // this test.
    let (counter, _, _) = __deploy__(5);

    // Get the initial counter value after deployment and verify it's set to 5.
    let count_1 = counter.get_counter();
    assert(count_1 == 5, 'invalid count');

    // Call the `decrease_counter` function to decrement the counter by 1.
    counter.decrease_counter();

    // Retrieve the new counter value after the decrease operation.
    let count_2 = counter.get_counter();

    // Verify that the counter value has decreased by exactly 1.
    assert(count_2 == count_1 - 1, 'invalid decrease count');
}

#[test]
fn test_emitted_decresed_event() {
    // Deploy the `counter` contract starting from ZERO_COUNT with initial deploy value of 5.
    let (counter, _, _) = __deploy__(5);

    // Create a spy instance to track and inspect emitted events during the test.
    let mut spy = spy_events();

    // Simulate a transaction coming from USER_1 by changing the caller address.
    start_cheat_caller_address(counter.contract_address, USER_1());

    // Call `decrease_counter` to  emit the `Decreased` event,
    counter.decrease_counter();

    // Stop the mocked caller context after the decrease_counter txn.
    stop_cheat_caller_address(counter.contract_address);

    // Assert that a `Decreased` event was emitted by the contract and was attributed to USER_1.
    spy
        .assert_emitted(
            @array![
                (
                    counter.contract_address,
                    Counter::Event::Decreased(Counter::Decreased { account: USER_1() }),
                ),
            ],
        );

    // Also assert that an `Increased` event was NOT emitted during this call.
    spy
        .assert_not_emitted(
            @array![
                (
                    counter.contract_address,
                    Counter::Event::Increased(Counter::Increased { account: USER_1() }),
                ),
            ],
        );
}


#[test]
// This attribute enables the use of the `safe_dispatcher` feature,
// which allows us to safely call external functions and handle errors gracefully.
#[feature("safe_dispatcher")]
fn test_safe_panic_reset_counter_by_non_owner() {
    // Deploy an instance of the `counter` contract with an initial count of ZERO_COUNT.
    // We also extract the `safe_dispatcher`, a special contract interface that lets us call methods
    // safely.
    let (counter, _, safe_dispatcher) = __deploy__(ZERO_COUNT);

    // Make sure the counter was initialized correctly.
    assert(counter.get_counter() == ZERO_COUNT, 'invalid count');

    // Change the caller address to `USER_1`, simulating a call from a non-owner account.
    // This is important because we want to test unauthorized access.
    start_cheat_caller_address(counter.contract_address, USER_1());

    // Reset the counter using the `safe_dispatcher`, which allows us to catch errors
    match safe_dispatcher.reset_counter() {
        // If the call somehow succeeds, it means our access control failed — so we panic the test.
        Result::Ok(_) => panic!("cannot reset"),
        // If the call fails (which is expected), we check that the error message matches
        // what we expect when a non-owner tries to reset the counter.
        Result::Err(e) => assert(*e[0] == 'Caller is not the owner', *e.at(0)),
    }
}


#[test]
fn test_successful_reset_counter() {
    let (counter, _, _) = __deploy__(5);

    // get count
    let count_1 = counter.get_counter();

    // assert that count = 5
    assert(count_1 == 5, 'invalid count');

    // changes the caller address to OWNER
    start_cheat_caller_address(counter.contract_address, OWNER());

    // execute reset_counter txn
    counter.reset_counter();

    // terminate call as OWNER
    stop_cheat_caller_address(counter.contract_address);

    let count_2 = counter.get_counter();

    // assert that count was successfully reset to 0
    assert(count_2 == 0, 'counter not reset');
}
