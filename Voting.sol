// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";


contract Voting is Ownable {

    struct Voter {
        //Describes a data structure type associated with each Voter
    bool isRegistered;
    bool hasVoted;
    uint votedProposalId;
    }

    struct Proposal {
        //Describes a data structure type associated with each Proposal made by a Voter during a Voting Session
        string description;
        uint voteCount;
        uint creationTime;
    }

    enum WorkflowStatus {
        //Describes the Status of the Vote 
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    mapping (address => Voter) Voters ;
    uint private  WinnerIndex ;

    Proposal[] private proposals;
    WorkflowStatus public Status ;
    address[] private addressesOfVoters; // OPTIONAL : only to use if you want your contract to be able to restart a voting session


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    constructor() {
        //Initialize the variables 
        Status = WorkflowStatus.RegisteringVoters;
        WinnerIndex = 0;
    }

 
    modifier onlyVoter() {
        //Limit the access only to the Voters
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
        //Add a Voter to a Whitelist and make him Registered
        require(Voters[_voterAddress].isRegistered != true, "this Voter is already registered");
        require(Status == WorkflowStatus.RegisteringVoters, "the registration of voters is over" );
        Voters[_voterAddress].isRegistered = true;
        addressesOfVoters.push(_voterAddress);
        emit VoterRegistered(_voterAddress);
    }


    function addProposal(string memory _proposal) external onlyVoter {
        //Add a Proposal in the dynamic array proposals
        require(Voters[msg.sender].isRegistered == true, "you are not a Voter");
        require(Status == WorkflowStatus.ProposalsRegistrationStarted, "It is not the time to add a Proposal" );
        for(uint i=0;i<proposals.length;i++) {
            require(StringEquals(proposals[i].description,_proposal)==false, "the Proposal has been already proposed");
                }

        Proposal memory proposal = Proposal(_proposal,0,block.timestamp);
        proposals.push(proposal);
        emit ProposalRegistered(proposals.length-1);
    }


    function Vote(uint _proposalId) external onlyVoter {
        //Allow each Voter to vote for one Proposal 
        //proposalId starts at 0
        require(Voters[msg.sender].hasVoted == false,"you have already voted");
        require(Status == WorkflowStatus.VotingSessionStarted, "It is not the time for the Voting Session to start");
        require(_proposalId>=0,"choose a positive number");
        require(_proposalId<proposals.length, "this proposalId does not exist");
        Voters[msg.sender].hasVoted = true;
        Voters[msg.sender].votedProposalId =_proposalId;
        proposals[_proposalId].voteCount ++;
        emit Voted (msg.sender,_proposalId);
    }

    function CountVotes() external onlyOwner returns (string memory,uint) {
        //Compare the Votes of all the proposals 
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

    function GetWinnerProposal() external view onlyVoter returns (string memory description, uint voteCount) {
        //Return the Winner Proposal with the largest amount of votes
        require(Status == WorkflowStatus.VotesTallied, "It is not the time to get the Winner Proposal");
        return (proposals[WinnerIndex].description,proposals[WinnerIndex].voteCount);
    }


    function getVoter(address _addr) external view onlyVoter returns(bool isRegistered,bool hasVoted,uint votedProposalId) {
        //Return all the info about a Voter 
        return (Voters[_addr].isRegistered,Voters[_addr].hasVoted,Voters[_addr].votedProposalId);
    }


    function HowManyProposals() external view onlyVoter returns(uint) {
        //Return the number of Proposal at a given time
         require(Status != WorkflowStatus.RegisteringVoters, "the registration of proposals has not started");
         return(proposals.length);
    }

    function GetProposalbyId(uint _proposalId) external view onlyVoter returns(string memory description,uint voteCount,uint creationTime) {
        //Get information about a Proposal 
        //proposalId starts at 0
        require(_proposalId<proposals.length,"this proposalId does not exist");
        return (proposals[_proposalId].description,proposals[_proposalId].voteCount,proposals[_proposalId].creationTime);
    }


    function resetVotingSession() external onlyOwner {
        // OPTIONAL : Allow the Owner to restart the Voting Session (Voters, proposals, Status), 
        // Can consume large quantity of gas
        require(Status==WorkflowStatus.VotesTallied, "It is not the time to restart the current Voting Session");
        Status = WorkflowStatus.RegisteringVoters;
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

    function StringEquals(string memory _a, string memory _b) private pure returns(bool) {
        //To be used internally in this contract 
         bool equality ;
        if ( keccak256( abi.encodePacked(_a) ) == keccak256( abi.encodePacked(_b) ) ){
            equality=true;
        }
        return equality;
    }    


}
