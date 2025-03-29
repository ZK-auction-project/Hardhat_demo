// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Verifier.sol";

contract Auction {
    struct Bid {
        string encrypt_bid;
        uint256 hash_bid1;
        uint256 hash_bid2;
    }

    uint256 public highestBid;
    uint256[2] public highestHash;
    address public winner;

    mapping (address => Bid) public bids;
    address public auctioneer;
    address[] public bidders;
    string public public_key;
    uint32 public min_bid;

    uint16 public voter;
    uint256[] public declare_bids;
    string[] public secret_key;

    VerifierRange public verifierRange;
    VerifierCompare public verifierCompare;

    constructor(address _verifierRange, address _verifierCompare) {
        verifierRange = VerifierRange(_verifierRange);
        verifierCompare = VerifierCompare(_verifierCompare);
    }

    modifier onlyAuctioneer {
        require(msg.sender == auctioneer);
        _;
    }

    function startAuction(string memory _public_key, uint32 _min_bid) public {
        auctioneer = msg.sender;
        public_key = _public_key;
        min_bid = _min_bid;
    }

    function bidding(string memory _encrypt_bid, uint256[2] memory _hash_bid, VerifierRange.Proof memory proof, uint[1] memory input) public {
        require(verifierRange.verifyTx(proof, input), "lower than min bid");
        Bid memory bid = Bid({
            encrypt_bid: _encrypt_bid,
            hash_bid1: _hash_bid[0],
            hash_bid2: _hash_bid[1]
        });
        bids[msg.sender] = bid; 
        bidders.push(msg.sender);
    }

    function endAuction(VerifierCompare.Proof memory proof, uint[10] memory input) onlyAuctioneer public{
        bool isValid = verifierCompare.verifyTx(proof, input);
        require(isValid, "proof not valid");
        uint position_winner;

        highestBid =  input[6]; 
        position_winner = input[7];
        highestHash = [input[8], input[9]];

        if (bids[bidders[position_winner]].hash_bid1 == highestHash[0] && bids[bidders[position_winner]].hash_bid2 == highestHash[1]){
            winner = bidders[position_winner];
        }
    }

    // function isBidder(address bidder) internal view returns (bool){
    //     for(uint i; i < bidders.length; i++){
    //         if (bidders[i] == bidder){
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    // function vote() public {
    //     require(isBidder(msg.sender), "Not participants");
    //     voter += 1;
    // }

    // function declareBids(string[] memory _secret_key, uint256[] memory _declare_bids) onlyAuctioneer public {
    //     require(voter >= 1, "Can't declare");
    //     secret_key = _secret_key;
    //     declare_bids = _declare_bids;
    // }
}