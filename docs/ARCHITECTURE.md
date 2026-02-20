# Aztec DAO Contract Architecture

## Contract Overview

```mermaid
flowchart TB
    subgraph USER["User"]
        direction TB
        U[""]
    end

    subgraph GOVERNANCE["GOVERNANCE Contract"]
        direction TB
        G["<b>Storage</b><br/>┌─────────────────────────────────────────────────────────────────────────────────┐<br/>│ members: MembersNote { members[10]: Field }                                         │<br/>│ treasury: AddressNote { address: AztecAddress }                                    │<br/>│ mem_contract: AddressNote { address: AztecAddress }                               │<br/>│ last_proposal_id: FieldNote { value: Field }                                    │<br/>│                                                                                 │<br/>│ <b>PrivateSet Notes:</b>                                                          │<br/>│ token_proposals: TokenProposalNote {                                            │<br/>│   proposal_id, token, amount, nft, nft_token_id, recipient,                    │<br/>│   final, threshold, votes_for, votes_against }                                   │<br/>│ member_proposals: MemberProposalNote {                                         │<br/>│   proposal_id, add, member, final, threshold, votes_for, votes_against }        │<br/>└─────────────────────────────────────────────────────────────────────────────────┘"]
    end

    subgraph TREASURY["TREASURY Contract"]
        direction TB
        T["<b>Storage</b><br/>┌─────────────────────────────────────────────────┐<br/>│ gov: AddressNote { address: AztecAddress }              │<br/>│       (Governance contract address)                    │<br/>└─────────────────────────────────────────────────┘"]
    end

    subgraph MEMBERS["MEMBERS Contract"]
        direction TB
        M["<b>Storage</b><br/>┌─────────────────────────────────────────────────────────────────────────────────┐<br/>│ gov: AddressNote { address: AztecAddress }                                         │<br/>│       (Governance contract address)                                                │<br/>│                                                                                 │<br/>│ <b>PrivateSet Notes:</b>                                                          │<br/>│ members: HatNote {                                                               │<br/>│   mem_contract, eligibility, maxSupply, supply, lastHatId,                      │<br/>│   toggle, config, token_id (HAT ID), hatted }                                    │<br/>└─────────────────────────────────────────────────────────────────────────────────┘"]
    end

    subgraph EXTERNAL["External"]
        direction TB
        E["Token (ERC20) · NFT (ERC721)"]
    end

    USER -->|"1. deploy"| GOVERNANCE
    USER -->|"2. add_treasury()"| GOVERNANCE
    USER -->|"3. add_mem_contract()"| GOVERNANCE

    GOVERNANCE -->|"cross-contract"| TREASURY
    GOVERNANCE -->|"cross-contract"| MEMBERS
    TREASURY -->|"transfer()"| EXTERNAL

    GOVERNANCE -.->|"creates proposals"| E
```

---

## Proposal Flow & Cross-Contract Calls

```mermaid
sequenceDiagram
    participant U as User/Member
    participant G as Governance
    participant M as Members
    participant T as Treasury
    participant X as Token/NFT

    Note over U,G: Setup
    G->>G: constructor(admin)
    U->>G: add_treasury(treasury)
    U->>G: add_mem_contract(members)

    Note over U,G: Create Proposal
    U->>G: create_token_proposal(token, amount, recipient, threshold)
    G->>G: Insert TokenProposalNote { final: false, votes_for: 0, votes_against: 0 }

    Note over U,G: Voting
    U->>G: cast_vote(proposal_id, FOR)
    G->>G: votes_for++, check threshold
    U->>G: cast_vote(proposal_id, AGAINST)
    G->>G: votes_against++

    Note over U,G: Finalize
    U->>G: finalize_proposal(proposal_id)
    G->>G: final = true

    Note over U,G: Execute (one of)
    alt Add Member
        U->>G: add_member(..., proposal_id)
        G->>M: add_member(...)
        M->>M: Insert HatNote
    else Remove Member
        U->>G: remove_member(proposal_id)
        G->>M: remove_member(member)
    else Withdraw
        U->>G: withdraw(proposal_id)
        G->>T: withdraw(token, amount, recipient)
        T->>X: transfer_private_to_private(from, to, amount)
    end
```

---

## Note Structures & Access Control

```mermaid
erDiagram
    GOVERNANCE ||--|| MEMBERS_NOTE : "storage.members"
    GOVERNANCE ||--|| ADDRESS_NOTE : "storage.treasury"
    GOVERNANCE ||--|| ADDRESS_NOTE : "storage.mem_contract"
    GOVERNANCE ||--|| FIELD_NOTE : "storage.last_proposal_id"
    GOVERNANCE ||--o{ TOKEN_PROPOSAL : "storage.token_proposals"
    GOVERNANCE ||--o{ MEMBER_PROPOSAL : "storage.member_proposals"
    TREASURY ||--|| ADDRESS_NOTE : "storage.gov"
    MEMBERS ||--|| ADDRESS_NOTE : "storage.gov"
    MEMBERS ||--o{ HAT_NOTE : "storage.members"

    MEMBERS_NOTE {
        array members "10 member addresses [0]=admin"
    }

    ADDRESS_NOTE {
        address addr "contract address"
    }

    FIELD_NOTE {
        field value "counter"
    }

    TOKEN_PROPOSAL {
        field proposal_id
        address token "token contract"
        uint128 amount
        bool nft
        field nft_token_id
        address recipient
        bool final
        uint32 threshold
        uint32 votes_for
        uint32 votes_against
    }

    MEMBER_PROPOSAL {
        field proposal_id
        bool add "true=add, false=remove"
        address member
        bool final
        uint32 threshold
        uint32 votes_for
        uint32 votes_against
    }

    HAT_NOTE {
        address mem_contract "this contract"
        address eligibility "claim eligibility"
        uint32 maxSupply
        uint32 supply
        uint16 lastHatId "child counter"
        address toggle
        uint16 config "active+mutable bits"
        field token_id "256-bit HAT ID"
        address hatted "token holder"
    }
```

---

## Access Control

| Function                        | Caller     | Check                                    |
| ------------------------------- | ---------- | ---------------------------------------- |
| Governance.create\_\*\_proposal | Member     | msg.sender in members[]                  |
| Governance.cast_vote            | Member     | msg.sender in members[]                  |
| Governance.finalize_proposal    | Admin      | msg.sender == members[0]                 |
| Governance.add_member           | Member     | msg.sender in members[] + proposal.final |
| Governance.remove_member        | Member     | msg.sender in members[] + proposal.final |
| Governance.withdraw             | Member     | msg.sender in members[] + proposal.final |
| Treasury.withdraw               | Governance | msg.sender == gov                        |
| Members.add_member              | Governance | msg.sender == gov                        |
| Members.remove_member           | Governance | msg.sender == gov                        |

---

## HATs Protocol (token_id)

```
┌────────────────────────────────────────────────────────────────────────┐
│ 256-bit Hat ID (token_id)                                             │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌──────────┬──────────┬──────────┬──────────┐   ┌──────────┐       │
│  │ 32 bits  │ 16 bits  │ 16 bits  │ 16 bits  │   │ 16 bits  │       │
│  │ TopHat   │ Level 0  │ Level 1  │ Level 2  │   │ Level 13 │       │
│  │ Domain   │ child 1  │ child 1  │ child 1  │   │ child 1  │       │
│  └──────────┴──────────┴──────────┴──────────┘   └──────────┘       │
│  ↑          ↑          ↑          ↑                  ↑                 │
│  bits 255   bits 223  bits 207   bits 191           bits 17          │
│  -224       -208       -192       -176                -0               │
│                                                                        │
│  MAX_LEVELS = 14 · Each level = 16 bits (max 65,536 children)       │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```
