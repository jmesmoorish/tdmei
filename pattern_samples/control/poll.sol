pragma solidity ^0.5.0;

contract Poll{
    struct Question{string description;bool complete;uint yes;uint no;
    mapping(address => bool) voters;string answer;}
    address public manager;Question[] public questions;
    modifier restricted(){require(msg.sender == manager);_;}
    constructor() public {manager=msg.sender;}
    
    function askQuestion(string description) public restricted {
        Question memory newQuestion = Question({
            description: description,complete: false,
            yes: 0,no: 0,answer: ''});
        questions.push(newQuestion);
    }
    
    function voteyes(uint index) public{
       Question storage question = questions[index];
       require(!question.complete);require(!question.voters[msg.sender]);
       question.voters[msg.sender] = true;question.yes++;
    }
    
    function voteno(uint index) public{
        Question storage question = questions[index];
        require(!question.complete);require(!question.voters[msg.sender]);
        question.voters[msg.sender] = true;question.no++;
    }
    
    function updateAnswer(uint index) public restricted{
        Question storage question = questions[index];
        require(!question.complete);
        if(question.yes >= question.no)
            question.answer = 'yes';
        else
            question.answer = 'no';
        question.complete = true;
    }

    function getAnswer(uint index) public restricted view returns (string){
        Question storage question = questions[index];
        require(question.complete);return question.answer;
    }
    function getQuestionLength() public view returns (uint){return questions.length;}
}



