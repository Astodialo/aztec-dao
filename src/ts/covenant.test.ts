import { GovernanceContract } from "../artifacts/Governance.js";
import { describe, it, expect, beforeEach } from "vitest";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { type AztecNode } from "@aztec/aztec.js/node";
import {
  assertOwnsPrivateNFT,
  deployGovernance,
  deployMembers,
  deployNFTWithMinter,
  deployTokenWithMinter,
  deployTreasury,
  expectTokenBalances,
  setupTestSuite,
} from "./utils.js";
import { AztecAddress } from "@aztec/stdlib/aztec-address";
import { Fr, GrumpkinScalar } from "@aztec/aztec.js/fields";
import { deriveKeys, PublicKeys } from "@aztec/stdlib/keys";
import { TokenContract } from "../artifacts/Token.js";
import { NFTContract } from "../artifacts/NFT.js";
import { TreasuryContract } from "../artifacts/Treasury.js";
import { MembersContract } from "../artifacts/Members.js";
import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";

describe("Gov Contract", () => {
  let node: AztecNode;
  let wallet: EmbeddedWallet;
  let accounts: AztecAddress[];

  let alice: AztecAddress;
  let bob: AztecAddress;
  let charlie: AztecAddress;
  let token: TokenContract;
  let nft: NFTContract;

  const AMOUNT = 1000n;
  const wad = (n: number = 1) => AMOUNT * BigInt(n);

  let treasury: TreasuryContract;
  let treasSk: Fr;
  let treasKeys: {
    masterNullifierHidingKey: GrumpkinScalar;
    masterIncomingViewingSecretKey: GrumpkinScalar;
    masterOutgoingViewingSecretKey: GrumpkinScalar;
    masterTaggingSecretKey: GrumpkinScalar;
    publicKeys: PublicKeys;
  };
  let treasSalt: Fr;

  let members: MembersContract;
  let memSk: Fr;
  let memKeys: {
    masterNullifierHidingKey: GrumpkinScalar;
    masterIncomingViewingSecretKey: GrumpkinScalar;
    masterOutgoingViewingSecretKey: GrumpkinScalar;
    masterTaggingSecretKey: GrumpkinScalar;
    publicKeys: PublicKeys;
  };
  let memSalt: Fr;

  let gov: GovernanceContract;
  let govSk: Fr;
  let govKeys: {
    masterNullifierHidingKey: GrumpkinScalar;
    masterIncomingViewingSecretKey: GrumpkinScalar;
    masterOutgoingViewingSecretKey: GrumpkinScalar;
    masterTaggingSecretKey: GrumpkinScalar;
    publicKeys: PublicKeys;
  };
  let govSalt: Fr;

  beforeEach(async () => {
    ({ node, wallet, accounts } = await setupTestSuite());

    [alice, bob, charlie] = accounts;

    treasSk = Fr.random();
    treasKeys = await deriveKeys(treasSk);
    treasSalt = Fr.random();

    memSk = Fr.random();
    memKeys = await deriveKeys(memSk);
    memSalt = Fr.random();

    govSk = Fr.random();
    govKeys = await deriveKeys(govSk);
    govSalt = Fr.random();

    gov = (await deployGovernance(
      govKeys.publicKeys,
      wallet,
      alice,
      govSalt,
      [alice],
      "constructor",
      govSk, // Pass secretKey for pre-registration
    )) as GovernanceContract;

    console.log("Gov address:", gov.address);

    treasury = (await deployTreasury(
      treasKeys.publicKeys,
      wallet,
      alice,
      treasSalt,
      [gov.address],
      "constructor",
      treasSk, // Pass secretKey for pre-registration
    )) as TreasuryContract;

    console.log("Treasury address:", treasury.address);

    members = (await deployMembers(
      memKeys.publicKeys,
      wallet,
      alice,
      memSalt,
      [gov.address, alice, 2, 2, 2, alice, 2, 0n, alice],
      "constructor",
      memSk, // Pass secretKey for pre-registration
    )) as MembersContract;

    console.log("Members address:", members.address);

    await gov
      .withWallet(wallet)
      .methods.add_treasury(treasury.address)
      .send({ from: alice });

    console.log("Treasury added");

    await gov
      .withWallet(wallet)
      .methods.add_mem_contract(members.address)
      .send({ from: alice });

    console.log("Members added");

    token = (await deployTokenWithMinter(wallet, alice)) as TokenContract;

    await token
      .withWallet(wallet)
      .methods.mint_to_private(treasury.address, AMOUNT)
      .send({ from: alice });
  });

  it("Deploys", async () => {
    const current_id = await gov.methods._view_current_id().simulate({
      from: alice,
    });

    const current_treasury = await gov.methods._view_treasury().simulate({
      from: alice,
    });

    const current_mem_contract = await gov.methods
      ._view_mem_contract()
      .simulate({
        from: alice,
      });

    const memmetis = await members.methods._view_member(alice).simulate({
      from: alice,
    });

    console.log(memmetis.hatted);
    console.log(alice);

    // starting counter's value is 0
    expect(current_id).toStrictEqual(0n);

    expect(current_treasury).toStrictEqual(treasury.address);

    expect(current_mem_contract).toStrictEqual(members.address);

    expect(memmetis.hatted.toBigInt()).toStrictEqual(alice.toBigInt());
  });

  it("withdraw directly from treasury as bob, should fail", async () => {
    await expect(
      treasury
        .withWallet(wallet)
        .methods.withdraw(token.address, AMOUNT, bob)
        .send({ from: bob }),
    ).rejects.toThrow(/Assertion failed: Not authorized/);
  });

  it("create token proposal from member, should succeed", async () => {
    await gov
      .withWallet(wallet)
      .methods.create_token_proposal(token.address, AMOUNT, false, 0n, bob, 1)
      .send({ from: alice });

    const proposal = await gov.methods._view_token_proposal(0n).simulate({
      from: alice,
    });

    expect(proposal.proposal_id).toStrictEqual(0n);
    expect(proposal.votes_for).toStrictEqual(0n);
    expect(proposal.votes_against).toStrictEqual(0n);

    const new_id = await gov.methods._view_current_id().simulate({
      from: alice,
    });
    //
    // After a new proposal has been created it should 1
    expect(new_id).toStrictEqual(1n);
  });

  it("create proposal from non member, should fail", async () => {
    await expect(
      gov
        .withWallet(wallet)
        .methods.create_token_proposal(token.address, AMOUNT, false, 0n, bob, 1)
        .send({ from: bob }),
    ).rejects.toThrow(/Assertion failed: Not a member/);

    const current_id = await gov.methods._view_current_id().simulate({
      from: bob,
    });
    //
    // After a new proposal has been created it should 1
    expect(current_id).toStrictEqual(0n);
  });

  describe("voting", async () => {
    beforeEach(async () => {
      await gov
        .withWallet(wallet)
        .methods.create_token_proposal(token.address, AMOUNT, false, 0n, bob, 2)
        .send({ from: alice });
    });

    it("vote on token proposal from member, should succeed", async () => {
      await gov
        .withWallet(wallet)
        .methods.cast_vote(0n, 1)
        .send({ from: alice });

      const new_proposal = await gov.methods
        ._view_token_proposal(0n)
        .simulate({ from: alice });
      expect(new_proposal.votes_for).toStrictEqual(1n);
      expect(new_proposal.final).toStrictEqual(false);
    });
    it("vote on token proposal from 2 members and finalize proposal, should succeed", async () => {
      await gov
        .withWallet(wallet)
        .methods.add_member(bob, 2, 2, 2, bob, 2, 1, bob)
        .send({ from: alice });

      await gov
        .withWallet(wallet)
        .methods.cast_vote(0n, 1)
        .send({ from: alice });

      const new_proposal = await gov.methods
        ._view_token_proposal(0n)
        .simulate({ from: alice });

      expect(new_proposal.votes_for).toStrictEqual(1n);
      expect(new_proposal.final).toStrictEqual(false);
      await gov.withWallet(wallet).methods.cast_vote(0n, 1).send({ from: bob });

      const nn_proposal = await gov.methods
        ._view_token_proposal(0n)
        .simulate({ from: alice });

      expect(nn_proposal.final).toStrictEqual(true);
      expect(nn_proposal.votes_for).toStrictEqual(2n);
    });
    it("vote on proposal from member a second time, should fail", async () => {
      await gov
        .withWallet(wallet)
        .methods.cast_vote(0n, 1)
        .send({ from: alice });

      const new_proposal = await gov.methods
        ._view_token_proposal(0n)
        .simulate({ from: alice });

      expect(new_proposal.votes_for).toStrictEqual(1n);
      await expect(
        gov.withWallet(wallet).methods.cast_vote(0n, 1).send({ from: alice }),
      ).rejects.toThrow("Invalid tx: Existing nullifier");

      const n_proposal = await gov.methods
        ._view_token_proposal(0n)
        .simulate({ from: alice });

      await expect(
        gov.withWallet(wallet).methods.cast_vote(0n, 0).send({ from: alice }),
      ).rejects.toThrow("Invalid tx: Existing nullifier");
      const nn_proposal = await gov.methods
        ._view_token_proposal(0n)
        .simulate({ from: alice });
    });

    it("vote on proposal from non member, should fail", async () => {
      await expect(
        gov.withWallet(wallet).methods.cast_vote(0n, 1).send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not a member/);

      const current_id = await gov.methods._view_current_id().simulate({
        from: bob,
      });

      // After a new proposal has been created it should be1
      expect(current_id).toStrictEqual(1n);
    });
  });

  describe("members", async () => {
    beforeEach(async () => {
      await gov
        .withWallet(wallet)
        .methods.create_token_proposal(token.address, AMOUNT, false, 0n, bob, 2)
        .send({ from: alice });
    });
    it("member adds a new member(bob), should succeed", async () => {
      await expect(
        gov
          .withWallet(wallet)
          .methods.create_token_proposal(
            token.address,
            AMOUNT,
            false,
            0n,
            bob,
            1,
          )
          .send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not a member/);

      await gov
        .withWallet(wallet)
        .methods.add_member(bob, 2, 2, 2, bob, 2, 1, bob)
        .send({ from: alice });

      const bob_hat = await members.methods._view_member(bob).simulate({
        from: bob,
      });

      expect(bob_hat.hatted).toStrictEqual(bob);

      console.log(bob_hat);

      await gov
        .withWallet(wallet)
        .methods.create_token_proposal(token.address, AMOUNT, false, 0n, bob, 1)
        .send({ from: bob });

      const proposal_id = await gov.methods
        ._view_current_id()
        .simulate({ from: bob });

      console.log(proposal_id);

      // After a new proposal has been created it should be1
      expect(proposal_id).toStrictEqual(2n);
    });

    it.only("not a member adds a new member(bob), should fail", async () => {
      await expect(
        gov
          .withWallet(wallet)
          .methods.add_member(bob, 2, 2, 2, bob, 2, 1, bob)
          .send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not a member/);

      await gov
        .withWallet(wallet)
        .methods.add_member(bob, 2, 2, 2, bob, 2, 1, bob)
        .send({ from: alice });

      await expect(
        gov
          .withWallet(wallet)
          .methods.add_member(charlie, 2, 2, 2, charlie, 2, 2, charlie)
          .send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not captain/);

      await expect(
        gov
          .withWallet(wallet)
          .methods.create_token_proposal(
            token.address,
            AMOUNT,
            false,
            0n,
            bob,
            1,
          )
          .send({ from: charlie }),
      ).rejects.toThrow(/Assertion failed: Not a member/);
    });

    it("captain removes a member, should succeed", async () => {
      await expect(
        gov
          .withWallet(wallet)
          .methods.create_token_proposal(
            token.address,
            AMOUNT,
            false,
            0n,
            bob,
            1,
          )
          .send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not a member/);

      await gov
        .withWallet(wallet)
        .methods.add_member(bob, 2, 2, 2, bob, 2, 1, bob)
        .send({ from: alice });

      await gov
        .withWallet(wallet)
        .methods.create_token_proposal(token.address, AMOUNT, false, 0n, bob, 1)
        .send({ from: bob });

      const proposal_id = await gov.methods
        ._view_current_id()
        .simulate({ from: bob });

      // After a new proposal has been created it should be 3
      expect(proposal_id).toStrictEqual(2n);

      await gov
        .withWallet(wallet)
        .methods.remove_member(bob)
        .send({ from: alice });

      await expect(
        gov
          .withWallet(wallet)
          .methods.create_token_proposal(
            token.address,
            AMOUNT,
            false,
            0n,
            bob,
            1,
          )
          .send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not a member/);
    });

    it("not captain removes a member, should fail", async () => {
      await expect(
        gov
          .withWallet(wallet)
          .methods.create_token_proposal(
            token.address,
            AMOUNT,
            false,
            0n,
            bob,
            1,
          )
          .send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not a member/);

      await gov
        .withWallet(wallet)
        .methods.add_member(bob, 2, 2, 2, bob, 2, 1, bob)
        .send({ from: alice });

      await gov
        .withWallet(wallet)
        .methods.create_token_proposal(token.address, AMOUNT, false, 0n, bob, 1)
        .send({ from: bob });

      const proposal_id = await gov.methods
        ._view_current_id()
        .simulate({ from: bob });

      // After a new proposal has been created it should be 3
      expect(proposal_id).toStrictEqual(2n);

      await expect(
        gov.withWallet(wallet).methods.remove_member(bob).send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not captain/);

      await gov
        .withWallet(wallet)
        .methods.remove_member(bob)
        .send({ from: alice });

      await expect(
        gov
          .withWallet(wallet)
          .methods.create_token_proposal(
            token.address,
            AMOUNT,
            false,
            0n,
            bob,
            1,
          )
          .send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not a member/);
    });
  });

  describe("withdraw", () => {
    beforeEach(async () => {
      await gov
        .withWallet(wallet)
        .methods.create_token_proposal(token.address, AMOUNT, false, 0n, bob, 1)
        .send({ from: alice });
    });

    it("proposal finalized, member should be able to withdraw", async () => {
      await expectTokenBalances(token, treasury.address, wad(0), AMOUNT, bob);
      await expectTokenBalances(token, bob, wad(0), wad(0));

      await gov
        .withWallet(wallet)
        .methods.cast_vote(0n, 1)
        .send({ from: alice });

      await gov.withWallet(wallet).methods.withdraw(0n).send({ from: alice });

      await expectTokenBalances(token, treasury.address, wad(0), wad(0), bob);
      await expectTokenBalances(token, bob, wad(0), AMOUNT);
    });

    it("proposal NOT finalized, member should NOT be able to withdraw", async () => {
      await expectTokenBalances(token, treasury.address, wad(0), AMOUNT, bob);
      await expectTokenBalances(token, bob, wad(0), wad(0));

      await expect(
        gov.withWallet(wallet).methods.withdraw(0n).send({ from: alice }),
      ).rejects.toThrow(/Assertion failed: Proposal not finalized/);

      await expectTokenBalances(token, treasury.address, wad(0), AMOUNT, bob);
      await expectTokenBalances(token, bob, wad(0), wad(0));
    });

    it("not a member should NOT be able to withdraw", async () => {
      await expectTokenBalances(token, treasury.address, wad(0), AMOUNT, bob);
      await expectTokenBalances(token, bob, wad(0), wad(0));

      await expect(
        gov.withWallet(wallet).methods.withdraw(0n).send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not a member/);

      await expectTokenBalances(token, treasury.address, wad(0), AMOUNT, bob);
      await expectTokenBalances(token, bob, wad(0), wad(0));
    });
  });
  describe("withdraw NFT", () => {
    let tokenId: bigint;

    beforeEach(async () => {
      tokenId = 1n;
      nft = (await deployNFTWithMinter(wallet, alice)) as NFTContract;
      await nft
        .withWallet(wallet)
        .methods.mint_to_private(treasury.address, tokenId)
        .send({ from: alice });

      await gov
        .withWallet(wallet)
        .methods.create_token_proposal(
          nft.address,
          AMOUNT,
          true,
          tokenId,
          bob,
          1,
        )
        .send({ from: alice });
    });

    it("member should be able to withdraw NFT correctly", async () => {
      await assertOwnsPrivateNFT(nft, tokenId, treasury.address, true, bob);
      await assertOwnsPrivateNFT(nft, tokenId, bob, false);

      console.log(nft.address);
      console.log(gov.address);
      console.log(treasury.address);

      await gov
        .withWallet(wallet)
        .methods.cast_vote(0n, 1)
        .send({ from: alice });

      console.log("voted");

      await gov.withWallet(wallet).methods.withdraw(0n).send({ from: alice });

      await assertOwnsPrivateNFT(nft, tokenId, treasury.address, false, bob);
      await assertOwnsPrivateNFT(nft, tokenId, bob, true);
    });

    it("not a member should NOT be able to withdraw NFT", async () => {
      await assertOwnsPrivateNFT(nft, tokenId, treasury.address, true, bob);
      await assertOwnsPrivateNFT(nft, tokenId, bob, false);

      await expect(
        gov.withWallet(wallet).methods.withdraw(0n).send({ from: bob }),
      ).rejects.toThrow(/Assertion failed: Not a member/);

      await assertOwnsPrivateNFT(nft, tokenId, treasury.address, true, bob);
      await assertOwnsPrivateNFT(nft, tokenId, bob, false);
    });
  });
});
