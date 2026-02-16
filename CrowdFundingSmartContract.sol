// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract crowdFunding{
    address public admin;
    mapping(address => uint) public contributors;
    uint public minContribution;
    uint public goal;
    uint public fundRaised;
    uint public deadline;
    uint public noOfContributors;

    struct Request{
        string description;
        uint value;
        address payable receipient;
        uint noOfVote;
        bool completed;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public noOfRequest;

    constructor(uint _goal, uint _deadline){
        admin = msg.sender;
        minContribution = 1 ether;
        goal = _goal;
        deadline = block.timestamp + _deadline;
    }

    function contribute() public payable{
        require(block.timestamp <= deadline);
        require(msg.value >= minContribution);
        if(contributors[msg.sender] == 0){
            noOfContributors += 1;
        }
        contributors[msg.sender] += msg.value;
        fundRaised += msg.value;
    }

    receive() external payable { 
        contribute();
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getRefund() public{
        require(block.timestamp > deadline && fundRaised < goal);

        uint value = contributors[msg.sender];
        contributors[msg.sender] = 0;

        payable(msg.sender).transfer(value);

    }

    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    function createRequest(string memory _description, uint _value, address payable _recipient) public onlyAdmin{
        Request storage newRequest = requests[noOfRequest];
        noOfRequest++;

        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.receipient = _recipient;
        newRequest.completed = false;
        newRequest.noOfVote = 0;
    }

    function voteRequest(uint _RequestId) public{
        require(contributors[msg.sender]>0);
        Request storage thisRequest = requests[_RequestId];
        require(thisRequest.voters[msg.sender]==false && thisRequest.completed==false);
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVote++;
    }

    function makePayment(uint _RequestId) public onlyAdmin{
        require(fundRaised>=goal);
        Request storage thisRequest = requests[_RequestId];
        require(thisRequest.completed==false);
        require(thisRequest.noOfVote>=noOfContributors/2,"vote is less than 50%");
        thisRequest.receipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}
