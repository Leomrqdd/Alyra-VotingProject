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
        uint creationTime;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    mapping (address => Voter) Voters ;
    uint public highestVotes = 0;
    uint public  WinnerIndex = 0;

    Proposal[] public proposals;
    WorkflowStatus public Status ;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    constructor() {
        Status = WorkflowStatus.RegisteringVoters;
    }

 
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


     function nextVotingStatus() public onlyOwner {
         require(Status != WorkflowStatus.VotesTallied, "It is time to choose a Winner Proposal");
         if(Status == WorkflowStatus.RegisteringVoters) {
             Status = WorkflowStatus.ProposalsRegistrationStarted;
             emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);    
         }
         else if (Status == WorkflowStatus.ProposalsRegistrationStarted) {
             Status = WorkflowStatus.ProposalsRegistrationEnded;
             emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);    

         }
        else if (Status == WorkflowStatus.ProposalsRegistrationEnded) {
             Status = WorkflowStatus.VotingSessionStarted;
             emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);    

         }
         else if (Status == WorkflowStatus.VotingSessionStarted) {
             Status = WorkflowStatus.VotingSessionEnded;
             emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);    

         }
         else if (Status == WorkflowStatus.VotingSessionEnded) {
             Status = WorkflowStatus.VotesTallied;
         }
             emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied); 
         }



    function addProposal(string memory _proposal) public onlyVoter {
        require(Voters[msg.sender].isRegistered == true, "you are not authorized");
        require(Status == WorkflowStatus.ProposalsRegistrationStarted, "It is not the time for the Registration to Start" );
        Proposal memory proposal = Proposal(_proposal,0,block.timestamp);
        proposals.push(proposal);
        emit ProposalRegistered(proposals.length);
    }


    function Vote(uint _proposalId) public onlyVoter {
        require(Voters[msg.sender].hasVoted == false,"you have already voted");
        require(Status == WorkflowStatus.VotingSessionStarted, "It is not the time for the Voting Session to start");
        Voters[msg.sender].hasVoted = true;
        Voters[msg.sender].votedProposalId =_proposalId;
        proposals[_proposalId].voteCount ++;
        emit Voted (msg.sender,_proposalId);
    }

    function CountVotes() public onlyOwner returns (string memory,uint) {
        require(Status == WorkflowStatus.VotesTallied, "It is not the time to count the Votes");
        for(uint i=0;i<proposals.length; i++) {
            if(proposals[i].voteCount>proposals[WinnerIndex].voteCount) {
                WinnerIndex = i;
                highestVotes = proposals[i].voteCount;
            }
            else if (proposals[i].voteCount==proposals[WinnerIndex].voteCount) {
                if(proposals[i].creationTime < proposals[WinnerIndex].creationTime) {
                    WinnerIndex = i;
                }
            }
        }
        return (proposals[WinnerIndex].description,highestVotes);
    }

    function GetWinnerProposal() public view onlyVoter returns (string memory, uint) {
        require(Status == WorkflowStatus.VotesTallied, "It is not the time to get the Winner Proposal");
        return (proposals[WinnerIndex].description,highestVotes);
    }

    
    function HowManyProposals() public view onlyVoter returns(uint) {
         require(Status != WorkflowStatus.RegisteringVoters, "the registration of proposals has not started");
         return(proposals.length);
    }








}
