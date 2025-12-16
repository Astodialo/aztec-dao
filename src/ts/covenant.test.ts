import { GovernanceContract, GovernanceContractArtifact } from "../artifacts/Governance.js";
import { describe, it, expect, beforeAll, beforeEach } from "vitest";
import { TestWallet } from "@aztec/test-wallet/server";
import { createAztecNodeClient } from "@aztec/aztec.js/node";
import { deployGovernance } from "./utils.js";
import { AztecAddress } from "@aztec/stdlib/aztec-address";

import {
  INITIAL_TEST_SECRET_KEYS,
  INITIAL_TEST_ACCOUNT_SALTS,
  INITIAL_TEST_ENCRYPTION_KEYS,
} from "@aztec/accounts/testing";
import { ContractDeployer } from "@aztec/aztec.js/deployment";

describe("Counter Contract", () => {
  let wallet: TestWallet;
  let alice: AztecAddress;
  let gov: GovernanceContract;

  beforeAll(async () => {
    const aztecNode = await createAztecNodeClient("http://localhost:8080", {});
    wallet = await TestWallet.create(
      aztecNode,
      {
        dataDirectory: "pxe-test",
        proverEnabled: false,
      },
      {},
    );

    // Register initial test accounts manually because of this:
    // https://github.com/AztecProtocol/aztec-packages/blame/next/yarn-project/accounts/src/schnorr/lazy.ts#L21-L25
    [alice] = await Promise.all(
      INITIAL_TEST_SECRET_KEYS.map(async (secret, i) => {
        const accountManager = await wallet.createSchnorrAccount(
          secret,
          INITIAL_TEST_ACCOUNT_SALTS[i],
          INITIAL_TEST_ENCRYPTION_KEYS[i],
        );
        return accountManager.address;
      }),
    );
  });

  beforeEach(async () => {
    gov = await deployGovernance(wallet, alice);
    console.log("Contract address: ", gov.address);
  });

  it("Deploys", async () => {
    const deployer = new ContractDeployer(GovernanceContractArtifact, wallet, undefined, 'constructor');
    const tx = deployer.deploy(alice).send({ from: alice });
    const receipt = await tx.getReceipt();
    console.log(receipt);

    const receiptAfter = await tx.wait({ wallet: wallet });

    console.log(receiptAfter);

    const current_id = await receiptAfter.contract.methods._view_current_id().simulate({
      from: alice,
    });

    console.log(current_id);

    // starting counter's value is 0
    // expect(current_id).toStrictEqual(alice);
  });
});
