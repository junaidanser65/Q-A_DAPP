// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedQA {
    struct Question {
        uint id;
        address asker;
        string title;
        string description;
        string category;
        uint voteCount;
        uint timestamp;
    }

    struct Answer {
        uint questionId;
        address responder;
        string text;
        uint voteCount;
        uint timestamp;
    }

    Question[] public questions;
    mapping(uint => Answer[]) public answers;
    mapping(address => mapping(uint => bool)) public hasVotedQuestion;
    mapping(address => mapping(uint => mapping(uint => bool))) public hasVotedAnswer;
    mapping(uint => bool) public questionRewarded;
    mapping(uint => mapping(uint => bool)) public answerRewarded;
    uint public rewardAmount = 0.01 ether;
    
    // Available categories
    string[] public categories = ["General", "Technical", "Blockchain", "Smart Contracts", "DeFi", "NFTs", "Gaming", "Other"];
    
    // Events for better frontend integration
    event QuestionAsked(uint indexed questionId, address indexed asker, string title, string category);
    event QuestionAnswered(uint indexed questionId, address indexed responder);
    event QuestionVoted(uint indexed questionId, address indexed voter);
    event AnswerVoted(uint indexed questionId, uint indexed answerIndex, address indexed voter);

    function askQuestion(string memory _title, string memory _description, string memory _category) public {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(bytes(_category).length > 0, "Category cannot be empty");
        
        uint questionId = questions.length;
        questions.push(Question(questionId, msg.sender, _title, _description, _category, 0, block.timestamp));
        
        emit QuestionAsked(questionId, msg.sender, _title, _category);
    }

    function answerQuestion(uint _questionId, string memory _text) public {
        require(_questionId < questions.length, "Question does not exist");
        require(bytes(_text).length > 0, "Answer cannot be empty");
        
        answers[_questionId].push(Answer(_questionId, msg.sender, _text, 0, block.timestamp));
        
        emit QuestionAnswered(_questionId, msg.sender);
    }

    function voteQuestion(uint _questionId) public {
        require(_questionId < questions.length, "Question does not exist");
        require(!hasVotedQuestion[msg.sender][_questionId], "Already voted");
        
        questions[_questionId].voteCount++;
        hasVotedQuestion[msg.sender][_questionId] = true;
        
        // Reward logic
        if (questions[_questionId].voteCount == 2 && !questionRewarded[_questionId]) {
            questionRewarded[_questionId] = true;
            address payable asker = payable(questions[_questionId].asker);
            if (address(this).balance >= rewardAmount) {
                asker.transfer(rewardAmount);
            }
        }
        
        emit QuestionVoted(_questionId, msg.sender);
    }

    function voteAnswer(uint _questionId, uint _answerIndex) public {
        require(_questionId < questions.length, "Question does not exist");
        require(_answerIndex < answers[_questionId].length, "Answer does not exist");
        require(!hasVotedAnswer[msg.sender][_questionId][_answerIndex], "Already voted");
        
        answers[_questionId][_answerIndex].voteCount++;
        hasVotedAnswer[msg.sender][_questionId][_answerIndex] = true;
        
        // Reward logic
        if (answers[_questionId][_answerIndex].voteCount == 2 && !answerRewarded[_questionId][_answerIndex]) {
            answerRewarded[_questionId][_answerIndex] = true;
            address payable responder = payable(answers[_questionId][_answerIndex].responder);
            if (address(this).balance >= rewardAmount) {
                responder.transfer(rewardAmount);
            }
        }
        
        emit AnswerVoted(_questionId, _answerIndex, msg.sender);
    }

    function getQuestions() public view returns (Question[] memory) {
        return questions;
    }

    function getQuestionsByCategory(string memory _category) public view returns (Question[] memory) {
        uint count = 0;
        for (uint i = 0; i < questions.length; i++) {
            if (keccak256(bytes(questions[i].category)) == keccak256(bytes(_category))) {
                count++;
            }
        }
        
        Question[] memory categoryQuestions = new Question[](count);
        uint index = 0;
        for (uint i = 0; i < questions.length; i++) {
            if (keccak256(bytes(questions[i].category)) == keccak256(bytes(_category))) {
                categoryQuestions[index] = questions[i];
                index++;
            }
        }
        return categoryQuestions;
    }

    function getAnswers(uint _questionId) public view returns (Answer[] memory) {
        return answers[_questionId];
    }
    
    function getCategories() public view returns (string[] memory) {
        return categories;
    }
    
    function getQuestionCount() public view returns (uint) {
        return questions.length;
    }
    
    function getQuestionCountByCategory(string memory _category) public view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < questions.length; i++) {
            if (keccak256(bytes(questions[i].category)) == keccak256(bytes(_category))) {
                count++;
            }
        }
        return count;
    }

    receive() external payable {}
}
