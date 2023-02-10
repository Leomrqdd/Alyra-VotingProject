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
    uint public highestVotes ;
    uint private  WinnerIndex ;

    Proposal[] public proposals;
    WorkflowStatus public Status ;
    address[] public addressesOfVoters; //WARNING : only to use if you want your contract to be able to restart a voting session, can consume large quantity of gas


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    constructor() {
        Status = WorkflowStatus.RegisteringVoters;
        WinnerIndex = 0;
    }

 
    modifier onlyVoter() {
        require (Voters[msg.sender].isRegistered == true, "you are not a Voter");
        _;
    }

     function nextVotingStatus() external onlyOwner {
         //Change the VotingStatus to the next one
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

    

    function addVoter (address _voterAddress) external onlyOwner {
        //Add a Voter to a Whitelist
        require(Voters[_voterAddress].isRegistered != true, "this Voter is already registered");
        require(Status == WorkflowStatus.RegisteringVoters, "the registration of voters is over" );
        Voters[_voterAddress].isRegistered = true;
        addressesOfVoters.push(_voterAddress);
        emit VoterRegistered(_voterAddress);
    }


    function addProposal(string memory _proposal) external onlyVoter {
        //Add a Proposal in the dynamic array proposals
        require(Voters[msg.sender].isRegistered == true, "you are not authorized");
        require(Status == WorkflowStatus.ProposalsRegistrationStarted, "It is not the time to add a Proposal" );
        Proposal memory proposal = Proposal(_proposal,0,block.timestamp);
        proposals.push(proposal);
        emit ProposalRegistered(proposals.length-1);
    }


    function Vote(uint _proposalId) external onlyVoter {
        //If you are a Voter : Vote for a Proposal
        //proposalId starts at 0
        require(Voters[msg.sender].hasVoted == false,"you have already voted");
        require(Status == WorkflowStatus.VotingSessionStarted, "It is not the time for the Voting Session to start");
        require(_proposalId>=0,"choose a positive number");
        Voters[msg.sender].hasVoted = true;
        Voters[msg.sender].votedProposalId =_proposalId;
        proposals[_proposalId].voteCount ++;
        emit Voted (msg.sender,_proposalId);
    }

    function CountVotes() external onlyOwner returns (string memory,uint) {
        //Count the Votes of all the proposals
        require(Status == WorkflowStatus.VotingSessionEnded, "It is not the time to count the Votes");
        for(uint i=0;i<proposals.length; i++) {
            if(proposals[i].voteCount>proposals[WinnerIndex].voteCount) {
                WinnerIndex = i;
            }
            else if (proposals[i].voteCount==proposals[WinnerIndex].voteCount) {
                if(proposals[i].creationTime < proposals[WinnerIndex].creationTime) {
                    WinnerIndex = i;
                }
            }
        }
        return (proposals[WinnerIndex].description,proposals[WinnerIndex].voteCount);
    }

    function GetWinnerProposal() external view onlyVoter returns (string memory, uint) {
        require(Status == WorkflowStatus.VotesTallied, "It is not the time to get the Winner Proposal");
        return (proposals[WinnerIndex].description,proposals[WinnerIndex].voteCount);
    }


    function getVoter(address _addr) external view onlyVoter returns(bool,bool,uint) {
        return (Voters[_addr].isRegistered,Voters[_addr].hasVoted,Voters[_addr].votedProposalId);
    }


    function HowManyProposals() external view onlyVoter returns(uint) {
         require(Status != WorkflowStatus.RegisteringVoters, "the registration of proposals has not started");
         return(proposals.length);
    }


    function resetVotingSession() external onlyOwner {
        // Allow the Owner to restart the Voting Session (Voters, proposals, Status)
        require(Status==WorkflowStatus.VotesTallied, "It is not the time to restart the current Voting Session");
        Status = WorkflowStatus.RegisteringVoters;
        highestVotes = 0;
        WinnerIndex = 0;

        while (proposals.length > 0) {
            proposals.pop();
        }

        for (uint i=0;i<addressesOfVoters.length;i++) {
            Voters[addressesOfVoters[i]].isRegistered=false;
            Voters[addressesOfVoters[i]].hasVoted=false;
            Voters[addressesOfVoters[i]].votedProposalId=0;
        }

        while (addressesOfVoters.length > 0) {
         addressesOfVoters.pop();
        }


    }



}
