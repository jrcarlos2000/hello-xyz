"use client";

import { ConnectedAddress } from "~~/components/ConnectedAddress";
import { useState } from "react";

const Home = () => {
  const [counterValue] = useState<number>(0);
  const [winNumber] = useState<number>(10);

  return (
    <div className="flex items-center flex-col flex-grow pt-10">
      <div className="px-5 w-full max-w-6xl">
        <h1 className="text-center mb-8">
          <span className="block text-4xl font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
            Counter Workshop
          </span>
          <div className="flex justify-center">
            <span className="text-base mt-2 badge badge-primary">
              {/* {targetNetwork.name} */}
              Network Name
            </span>
          </div>
        </h1>
        <ConnectedAddress />
        <div className="mt-8 space-y-6">
          <div className="bg-base-100 p-8 rounded-3xl border border-gradient shadow-lg">
            <h2 className="text-2xl font-bold mb-6 text-secondary">
              Counter Game
            </h2>
            <div className="p-4 bg-base-200 rounded-xl">
              <h3 className="text-lg font-semibold mb-2">Current Count</h3>
              <p className="text-5xl font-bold text-center my-4">
                {counterValue.toString()}
                <span className="text-xl opacity-60 ml-2">/ {winNumber.toString()}</span>
              </p>
              <p className="text-center text-lg mb-4">
                Reach {winNumber.toString()} to win all STRK in the contract!
              </p>
              <div className="flex justify-center gap-4 mt-4">
                <button
                  className="btn btn-primary btn-lg"
                  onClick={() => console.log("Increment counter")}
                >
                  Increment
                </button>
                <button
                  className="btn btn-secondary btn-lg"
                  onClick={() => console.log("Decrement counter")}
                >
                  Decrement
                </button>
                <button
                  className="btn btn-outline btn-lg"
                  onClick={() => console.log("Reset counter")}
                >
                  Reset
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;