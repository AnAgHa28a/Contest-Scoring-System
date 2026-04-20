// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CodingContest {
    address public organizer;
    bool public finalized;

    uint256 public constant WEIGHT_PROBLEM_SOLVING = 40;
    uint256 public constant WEIGHT_CODE_QUALITY = 30;
    uint256 public constant WEIGHT_EFFICIENCY = 30;

    uint256 public constant MAX_PROBLEM_SOLVING = 100;
    uint256 public constant MAX_CODE_QUALITY = 100;
    uint256 public constant MAX_EFFICIENCY = 100;

    struct Score {
        uint256 problemSolving;
        uint256 codeQuality;
        uint256 efficiency;
        bool submitted;
    }

    struct Participant {
        address addr;
        string name;
        bool registered;
    }

    struct Judge {
        address addr;
        string name;
        bool registered;
        address[] assignedParticipants;
        uint256 submittedCount;
    }

    struct LeaderboardEntry {
        address participant;
        string name;
        uint256 totalWeighted;
        uint256 judgesCount;
        uint256 averageWeighted;
    }

    address[] public participantList;
    address[] public judgeList;

    mapping(address => Participant) public participants;
    mapping(address => Judge) public judges;
    mapping(address => mapping(address => Score)) public scores;
    mapping(address => mapping(address => bool)) public isAssigned;

    event ParticipantRegistered(address indexed participant, string name);
    event JudgeRegistered(address indexed judge, string name);
    event JudgeAssigned(address indexed judge, address indexed participant);
    event ScoreSubmitted(
        address indexed judge,
        address indexed participant,
        uint256 problemSolving,
        uint256 codeQuality,
        uint256 efficiency,
        uint256 weightedScore
    );
    event ContestFinalized();

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer");
        _;
    }

    modifier onlyJudge() {
        require(judges[msg.sender].registered, "Not a registered judge");
        _;
    }

    modifier notFinalized() {
        require(!finalized, "Contest already finalized");
        _;
    }

    constructor() {
        organizer = msg.sender;
    }

    function registerParticipant(address _addr, string calldata _name)
        external
        onlyOrganizer
        notFinalized
    {
        require(_addr != address(0), "Invalid participant address");
        require(bytes(_name).length > 0, "Participant name required");
        require(!participants[_addr].registered, "Already registered as participant");
        require(!judges[_addr].registered, "Address already registered as judge");

        participants[_addr] = Participant(_addr, _name, true);
        participantList.push(_addr);

        emit ParticipantRegistered(_addr, _name);
    }

    function registerJudge(address _addr, string calldata _name)
        external
        onlyOrganizer
        notFinalized
    {
        require(_addr != address(0), "Invalid judge address");
        require(bytes(_name).length > 0, "Judge name required");
        require(!judges[_addr].registered, "Already registered as judge");
        require(!participants[_addr].registered, "Address already registered as participant");

        judges[_addr].addr = _addr;
        judges[_addr].name = _name;
        judges[_addr].registered = true;
        judgeList.push(_addr);

        emit JudgeRegistered(_addr, _name);
    }

    function assignJudgeToParticipant(address _judge, address _participant)
        external
        onlyOrganizer
        notFinalized
    {
        require(judges[_judge].registered, "Not a registered judge");
        require(participants[_participant].registered, "Not a registered participant");
        require(!isAssigned[_judge][_participant], "Already assigned");

        judges[_judge].assignedParticipants.push(_participant);
        isAssigned[_judge][_participant] = true;

        emit JudgeAssigned(_judge, _participant);
    }

    function submitScore(
        address _participant,
        uint256 _problemSolving,
        uint256 _codeQuality,
        uint256 _efficiency
    ) external onlyJudge notFinalized {
        require(participants[_participant].registered, "Participant not registered");
        require(isAssigned[msg.sender][_participant], "Not assigned to this participant");
        require(!scores[msg.sender][_participant].submitted, "Score already submitted");
        require(_problemSolving <= MAX_PROBLEM_SOLVING, "Problem solving score too high");
        require(_codeQuality <= MAX_CODE_QUALITY, "Code quality score too high");
        require(_efficiency <= MAX_EFFICIENCY, "Efficiency score too high");

        scores[msg.sender][_participant] = Score(
            _problemSolving,
            _codeQuality,
            _efficiency,
            true
        );

        judges[msg.sender].submittedCount++;

        uint256 weighted = (
            _problemSolving * WEIGHT_PROBLEM_SOLVING +
            _codeQuality * WEIGHT_CODE_QUALITY +
            _efficiency * WEIGHT_EFFICIENCY
        ) / 100;

        emit ScoreSubmitted(
            msg.sender,
            _participant,
            _problemSolving,
            _codeQuality,
            _efficiency,
            weighted
        );
    }

    function finalizeContest() external onlyOrganizer notFinalized {
        require(participantList.length > 0, "No participants registered");
        require(judgeList.length > 0, "No judges registered");

        for (uint256 i = 0; i < judgeList.length; i++) {
            Judge storage j = judges[judgeList[i]];
            require(
                j.submittedCount == j.assignedParticipants.length,
                "Not all judges have submitted all scores"
            );
        }

        finalized = true;
        emit ContestFinalized();
    }

    function canFinalize() external view returns (bool) {
        if (finalized) {
            return false;
        }

        if (participantList.length == 0 || judgeList.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < judgeList.length; i++) {
            Judge storage j = judges[judgeList[i]];
            if (j.submittedCount != j.assignedParticipants.length) {
                return false;
            }
        }

        return true;
    }

    function getParticipantList() external view returns (address[] memory) {
        return participantList;
    }

    function getJudgeList() external view returns (address[] memory) {
        return judgeList;
    }

    function getAssignedParticipants(address _judge) external view returns (address[] memory) {
        return judges[_judge].assignedParticipants;
    }

    function getParticipantScore(address _participant)
        public
        view
        returns (uint256 totalWeighted, uint256 judgesCount)
    {
        for (uint256 i = 0; i < judgeList.length; i++) {
            address j = judgeList[i];
            if (isAssigned[j][_participant] && scores[j][_participant].submitted) {
                Score memory s = scores[j][_participant];
                totalWeighted += (
                    s.problemSolving * WEIGHT_PROBLEM_SOLVING +
                    s.codeQuality * WEIGHT_CODE_QUALITY +
                    s.efficiency * WEIGHT_EFFICIENCY
                ) / 100;
                judgesCount++;
            }
        }
    }

    function getParticipantAverageScore(address _participant) public view returns (uint256) {
        (uint256 totalWeighted, uint256 judgesCount) = getParticipantScore(_participant);
        if (judgesCount == 0) {
            return 0;
        }
        return totalWeighted / judgesCount;
    }

    function getScore(address _judge, address _participant)
        external
        view
        returns (uint256 ps, uint256 cq, uint256 eff, bool submitted)
    {
        Score memory s = scores[_judge][_participant];
        return (s.problemSolving, s.codeQuality, s.efficiency, s.submitted);
    }

    function getJudgeProgress(address _judge)
        external
        view
        returns (uint256 submitted, uint256 total)
    {
        Judge storage j = judges[_judge];
        return (j.submittedCount, j.assignedParticipants.length);
    }

    function getLeaderboard() external view returns (LeaderboardEntry[] memory) {
        LeaderboardEntry[] memory board = new LeaderboardEntry[](participantList.length);

        for (uint256 i = 0; i < participantList.length; i++) {
            address p = participantList[i];
            (uint256 totalWeighted, uint256 judgesCount) = getParticipantScore(p);

            uint256 averageWeighted = 0;
            if (judgesCount > 0) {
                averageWeighted = totalWeighted / judgesCount;
            }

            board[i] = LeaderboardEntry(
                p,
                participants[p].name,
                totalWeighted,
                judgesCount,
                averageWeighted
            );
        }

        for (uint256 i = 0; i < board.length; i++) {
            for (uint256 j = i + 1; j < board.length; j++) {
                if (board[j].averageWeighted > board[i].averageWeighted) {
                    LeaderboardEntry memory temp = board[i];
                    board[i] = board[j];
                    board[j] = temp;
                }
            }
        }

        return board;
    }
}