// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";


contract Voting is Ownable {

    struct Voter {
    bool isRegistered;
    bool hasVoted;
    uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    mapping (address => Voter) Voters ;
    Proposal[] public proposals;
    WorkflowStatus public Status = WorkflowStatus.RegisteringVoters;

    uint public highestVotes = 0;
    uint public  WinnerIndex = 0;

    modifier onlyVoter() {
        require (Voters[msg.sender].isRegistered == true, "you are not a Voter");
        _;
    }

    function addVoter (address _voterAddress) public onlyOwner {
        require(Voters[_voterAddress].isRegistered != true, "this Voter is already registered");
        require(Status == WorkflowStatus.RegisteringVoters, "the registration of voters is over" );
        Voters[_voterAddress].isRegistered = true;
        emit VoterRegistered(_voterAddress);
    }

    function getVoter(address _addr) public view onlyVoter returns(bool,bool,uint) {
        return (Voters[_addr].isRegistered,Voters[_addr].hasVoted,Voters[_addr].votedProposalId);
    }



     function startProposalRegistration() public onlyOwner {
         Status = WorkflowStatus.ProposalsRegistrationStarted;
     }

    function addProposal(string memory _proposal) public onlyVoter {
        require(Voters[msg.sender].isRegistered == true, "you are not authorized");
        require(Status == WorkflowStatus.ProposalsRegistrationStarted, "the registration of voters is over" );
        Proposal memory proposal = Proposal(_proposal,0);
        proposals.push(proposal);
        emit ProposalRegistered(proposals.length);
    }


    function endProposalRegistration() public onlyOwner {
         Status = WorkflowStatus.ProposalsRegistrationEnded;
    }


    function startVotingSession() public onlyOwner {
         Status = WorkflowStatus.VotingSessionStarted;

    }

    function Vote(uint _proposalId) public onlyVoter {
        require(Voters[msg.sender].hasVoted == false,"you have already voted");
        require(Status == WorkflowStatus.VotingSessionStarted, "the voting session has not started yet");
        Voters[msg.sender].hasVoted = true;
        Voters[msg.sender].votedProposalId =_proposalId;
        proposals[_proposalId].voteCount ++;
        emit Voted (msg.sender,_proposalId);
    }

    function EndVotingSession() public onlyOwner {
         Status = WorkflowStatus.VotingSessionEnded;

    }

   function StartCountVotes() public onlyOwner {
         Status = WorkflowStatus.VotesTallied;

    }

    function CountVotes() public onlyOwner returns (string memory,uint) {
        require(Status == WorkflowStatus.VotesTallied, "the voting session is not over yet");
        for(uint i=0;i<proposals.length; i++) {
            if(proposals[i].voteCount>proposals[WinnerIndex].voteCount) {
                WinnerIndex = i;
                highestVotes = proposals[i].voteCount;
            }
        }
        return (proposals[WinnerIndex].description,highestVotes);
    }

    function GetWinnerProposal() public view returns (string memory, uint) {
        return (proposals[WinnerIndex].description,highestVotes);
    }

    
    function HowManyProposals() public view onlyVoter returns(uint) {
         require(Status == WorkflowStatus.ProposalsRegistrationEnded, "the registration of proposals is not over yet");
         return(proposals.length);
    }

    function getProposalDetails(uint256 _proposalId) public view onlyVoter returns (string memory,uint) {
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.description, proposal.voteCount);
    }

    




}
