pragma solidity ^0.5.5;

//import "./LockableToken.sol";
//import "./MultiOwnable.sol";
//import "./SafeMath.sol";
//import "./StandardToken.sol";
//import "./ERC20Basic.sol";
//import "./ERC20.sol"; 
//import "./BasicToken.sol"; 
//import "./DoDreamChainBase.sol.sol";

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from], "Not enough balance.");
    require(_value <= allowed[_from][msg.sender], "Not allowed.");
    require(_to != address(0), "Invalid address.");

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MultiOwnable {
  address public root;
  mapping (address => address) public owners;

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() public {
    root = msg.sender;
    owners[root] = root;
  }

  /**
  * @dev check owner
  */
  modifier onlyOwner() {
    require(owners[msg.sender] != address(0), "permission error[onlyOwner]");
    _;
  }

   modifier onlyRoot() {
    require(msg.sender == root, "permission error[onlyRoot]");
    _;
  }

  /**
  * @dev add new owner
  */
  function newOwner(address _owner) external onlyOwner returns (bool) {
    require(_owner != address(0), "Invalid address.");
    require(owners[_owner] == address(0), "permission error[onlyOwner]");
    owners[_owner] = msg.sender;
    return true;
  }

  /**
    * @dev delete owner
    */
  function deleteOwner(address _owner) external onlyOwner returns (bool) {
    owners[_owner] = address(0);
    return true;
  }
}

contract MultiOwnable {
  address public root;
  mapping (address => address) public owners;

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() public {
    root = msg.sender;
    owners[root] = root;
  }

  /**
  * @dev check owner
  */
  modifier onlyOwner() {
    require(owners[msg.sender] != address(0), "permission error[onlyOwner]");
    _;
  }

   modifier onlyRoot() {
    require(msg.sender == root, "permission error[onlyRoot]");
    _;
  }

  /**
  * @dev add new owner
  */
  function newOwner(address _owner) external onlyOwner returns (bool) {
    require(_owner != address(0), "Invalid address.");
    require(owners[_owner] == address(0), "permission error[onlyOwner]");
    owners[_owner] = msg.sender;
    return true;
  }

  /**
    * @dev delete owner
    */
  function deleteOwner(address _owner) external onlyOwner returns (bool) {
    owners[_owner] = address(0);
    return true;
  }
}

contract LockableToken is StandardToken, MultiOwnable {
    bool public locked = true;

    /**
     * dev 락 = TRUE  이여도  거래 가능한 언락 계정
     */
    mapping(address => bool) public unlockAddrs;

    /**
     * dev - 계정마다 lockValue만큼 락이 걸린다.
     * dev - lockValue = 0 > limit이 없음
     */
    mapping(address => uint256) public lockValues;

    event Locked(bool locked, string note);
    event LockedTo(address indexed addr, bool locked, string note);
    event SetLockValue(address indexed addr, uint256 value, string note);

    constructor() public {
        unlockTo(msg.sender,  "");
    }

    modifier checkUnlock (address addr, uint256 value) {
        require(!locked || unlockAddrs[addr], "The account is currently locked.");
        require(balances[addr].sub(value) >= lockValues[addr], "Transferable limit exceeded. Check the status of the lock value.");
        _;
    }

    function lock(string memory note) public onlyOwner {
        locked = true;
        emit Locked(locked, note);
    }

    function unlock(string memory note) public onlyOwner {
        locked = false;
        emit Locked(locked, note);
    }

    function lockTo(address addr, string memory note) public onlyOwner {
        setLockValue(addr, balanceOf(addr), note);
        unlockAddrs[addr] = false;

        emit LockedTo(addr, true, note);
    }

    function unlockTo(address addr, string memory note) public onlyOwner {
        setLockValue(addr, 0, note);
        unlockAddrs[addr] = true;

        emit LockedTo(addr, false, note);
    }

    function setLockValue(address addr, uint256 value, string memory note) public onlyOwner {
        lockValues[addr] = value;
        if(value == 0){
            unlockAddrs[addr] = true;    
        }else{
            unlockAddrs[addr] = false;
        }

        emit SetLockValue(addr, value, note);
    }

    /**
     * dev 이체 가능 금액 체크
     */
    function getMyUnlockValue() public view returns (uint256) {
        address addr = msg.sender;
        if ((!locked || unlockAddrs[addr]) )
            return balances[addr].sub(lockValues[addr]);
        else
            return 0;
    }

    function transfer(address to, uint256 value) public checkUnlock(msg.sender, value) returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public checkUnlock(from, value) returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract DoDreamChainBase is LockableToken   {
    event DRMTransfer(address indexed from, address indexed to, uint256 value, string note);
    event DRMTransferFrom(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event DRMApproval(address indexed owner, address indexed spender, uint256 value, string note);

    event DRMMintTo(address indexed controller, address indexed to, uint256 amount, string note);
    event DRMBurnFrom(address indexed controller, address indexed from, uint256 value, string note);

    event DRMTransferToTeam(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event DRMTransferToPartner(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);

    event DRMTransferToEcosystem(address indexed owner, address indexed spender, address indexed to
    , uint256 value, uint256 processIdHash, uint256 userIdHash, string note);

    // ERC20 함수들을 오버라이딩 작업 > drm~ 함수를 타게 한다.
    function transfer(address to, uint256 value) public returns (bool ret) {
        return drmTransfer(to, value, "transfer");
    }

    function drmTransfer(address to, uint256 value, string memory note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transfer(to, value);
        emit DRMTransfer(msg.sender, to, value, note);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return drmTransferFrom(from, to, value, "");
    }
             
     function drmTransferFrom(address from, address to, uint256 value, string memory note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transferFrom(from, to, value);
        emit DRMTransferFrom(from, msg.sender, to, value, note);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        return drmApprove(spender, value, "");
    }

    function drmApprove(address spender, uint256 value, string memory note) public returns (bool ret) {
        ret = super.approve(spender, value);
        emit DRMApproval(msg.sender, spender, value, note);
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        return drmIncreaseApproval(spender, addedValue, "");
    }

    function drmIncreaseApproval(address spender, uint256 addedValue, string memory note) public returns (bool ret) {
        ret = super.increaseApproval(spender, addedValue);
        emit DRMApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        return drmDecreaseApproval(spender, subtractedValue, "");
    }

    function drmDecreaseApproval(address spender, uint256 subtractedValue, string memory note) public returns (bool ret) {
        ret = super.decreaseApproval(spender, subtractedValue);
        emit DRMApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    /**
     * dev 신규 발행시 반드시 주석을 남길수 있도록한다.
     */
    function mintTo(address to, uint256 amount) internal returns (bool) {
        require(to != address(0x0), "This address to be set is zero address(0). Check the input address.");
    
        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);

        emit Transfer(address(0), to, amount);
        return true;
    }

    function drmMintTo(address to, uint256 amount, string memory note) public onlyOwner returns (bool ret) {
        ret = mintTo(to, amount);
        emit DRMMintTo(msg.sender, to, amount, note);
    }

    /**
     * dev 화폐 소각시 반드시 주석을 남길수 있도록한다.
     */
    function burnFrom(address from, uint256 value) internal returns (bool) {
        require(value <= balances[from], "Your balance is insufficient.");

        balances[from] = balances[from].sub(value);
        totalSupply_ = totalSupply_.sub(value);

        emit Transfer(from, address(0), value);
        return true;
    }

    function drmBurnFrom(address from, uint256 value, string memory note) public onlyOwner returns (bool ret) {
        ret = burnFrom(from, value);
        emit DRMBurnFrom(msg.sender, from, value, note);
    }
    
    /**
     * dev DRM 팀에게 전송하는 경우
     */
    function drmTransferToTeam(
        address from,
        address to,
        uint256 value,
        string memory note
    ) public onlyOwner returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transferFrom(from, to, value);
        emit DRMTransferToTeam(from, msg.sender, to, value, note);
        return ret;
    }
    
    /**
     * dev 파트너(어드바이저)에게 전송하는 경우
     */
    function drmTransferToPartner(
        address from,
        address to,
        uint256 value,
        string memory note
    ) public onlyOwner returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transferFrom(from, to, value);
        emit DRMTransferToPartner(from, msg.sender, to, value, note);
    }

    /**
     * dev 보상을 DRM 지급
     * dev EOA가 트랜잭션을 일으켜서 처리 * 여러개 계좌를 기준으로 한다. (가스비 아끼기 위함)
     */
    function drmBatchTransferToEcosystem(
        address from, address[] memory to,
        uint256[] memory values,
        uint256 processIdHash,
        uint256[] memory userIdHash,
        string memory note
    ) public onlyOwner returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length, "The sizes of \'to\' and \'values\' arrays are different.");
        require(length == userIdHash.length, "The sizes of \'to\' and \'userIdHash\' arrays are different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of DoDreamChain.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit DRMTransferToEcosystem(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }
    
    function destroy() public onlyRoot {
        selfdestruct(msg.sender);
    }
   
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender], "The balance of account is insufficient.");
    require(_to != address(0), "Recipient address is zero address(0). Check the address again.");

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract DoDreamChain is DoDreamChainBase {

  event TransferedToDRMDapp(
        address indexed owner,
        address indexed spender,
        address indexed to, uint256 value, DRMReceiver.DRMReceiveType receiveType);

  string public constant name = "DoDreamChain";
  string public constant symbol = "DRM";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 250 * 1000 * 1000 * (10 ** uint256(decimals)); // 250,000,000 DRM

  /**
   * @dev Constructor 생성자에게 DRM토큰을 보냅니다.
   */
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }

  function drmTransfer(address _to, uint256 _value, string memory  _note) public returns (bool ret) {
      ret = super.drmTransfer(_to, _value, _note);
      postTransfer(msg.sender, msg.sender, _to, _value, DRMReceiver.DRMReceiveType.DRM_TRANSFER);
  }

  function drmTransferFrom(address _from, address _to, uint256 _value, string memory _note) public returns (bool ret) {
      ret = super.drmTransferFrom(_from, _to, _value, _note);
      postTransfer(_from, msg.sender, _to, _value, DRMReceiver.DRMReceiveType.DRM_TRANSFER);
  }

  function postTransfer(address owner, address spender, address to, uint256 value,
   DRMReceiver.DRMReceiveType receiveType) internal returns (bool) {
        if (Address.isContract(to)) {
            
            (bool callOk, bytes memory data) = address(to).call(abi.encodeWithSignature("onDRMReceived(address,address,uint256,uint8)", owner, spender, value, receiveType));
            if (callOk) {
                emit TransferedToDRMDapp(owner, spender, to, value, receiveType);
            }
        }

        return true;
    }

  function drmMintTo(address to, uint256 amount, string memory note) public onlyOwner returns (bool ret) {
        ret = super.drmMintTo(to, amount, note);
        postTransfer(address(0), msg.sender, to, amount, DRMReceiver.DRMReceiveType.DRM_MINT);
    }

    function drmBurnFrom(address from, uint256 value, string memory note) public onlyOwner returns (bool ret) {
        ret = super.drmBurnFrom(from, value, note);
        postTransfer(address(0), msg.sender, from, value, DRMReceiver.DRMReceiveType.DRM_BURN);
    }

}

/**
 * @title DRM Receiver
 */
contract DRMReceiver {
    enum DRMReceiveType { DRM_TRANSFER, DRM_MINT, DRM_BURN }
    function onDRMReceived(address owner, address spender, uint256 value, DRMReceiveType receiveType) public returns (bool);
}

/**
 * @title DRMBaseToken
 * dev 트랜잭션 실행 시 메모를 남길 수 있다.
 */
contract DoDreamChainBase is LockableToken   {
    event DRMTransfer(address indexed from, address indexed to, uint256 value, string note);
    event DRMTransferFrom(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event DRMApproval(address indexed owner, address indexed spender, uint256 value, string note);

    event DRMMintTo(address indexed controller, address indexed to, uint256 amount, string note);
    event DRMBurnFrom(address indexed controller, address indexed from, uint256 value, string note);

    event DRMTransferToTeam(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event DRMTransferToPartner(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);

    event DRMTransferToEcosystem(address indexed owner, address indexed spender, address indexed to
    , uint256 value, uint256 processIdHash, uint256 userIdHash, string note);

    // ERC20 함수들을 오버라이딩 작업 > drm~ 함수를 타게 한다.
    function transfer(address to, uint256 value) public returns (bool ret) {
        return drmTransfer(to, value, "transfer");
    }

    function drmTransfer(address to, uint256 value, string memory note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transfer(to, value);
        emit DRMTransfer(msg.sender, to, value, note);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return drmTransferFrom(from, to, value, "");
    }
             
     function drmTransferFrom(address from, address to, uint256 value, string memory note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transferFrom(from, to, value);
        emit DRMTransferFrom(from, msg.sender, to, value, note);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        return drmApprove(spender, value, "");
    }

    function drmApprove(address spender, uint256 value, string memory note) public returns (bool ret) {
        ret = super.approve(spender, value);
        emit DRMApproval(msg.sender, spender, value, note);
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        return drmIncreaseApproval(spender, addedValue, "");
    }

    function drmIncreaseApproval(address spender, uint256 addedValue, string memory note) public returns (bool ret) {
        ret = super.increaseApproval(spender, addedValue);
        emit DRMApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        return drmDecreaseApproval(spender, subtractedValue, "");
    }

    function drmDecreaseApproval(address spender, uint256 subtractedValue, string memory note) public returns (bool ret) {
        ret = super.decreaseApproval(spender, subtractedValue);
        emit DRMApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    /**
     * dev 신규 발행시 반드시 주석을 남길수 있도록한다.
     */
    function mintTo(address to, uint256 amount) internal returns (bool) {
        require(to != address(0x0), "This address to be set is zero address(0). Check the input address.");
    
        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);

        emit Transfer(address(0), to, amount);
        return true;
    }

    function drmMintTo(address to, uint256 amount, string memory note) public onlyOwner returns (bool ret) {
        ret = mintTo(to, amount);
        emit DRMMintTo(msg.sender, to, amount, note);
    }

    /**
     * dev 화폐 소각시 반드시 주석을 남길수 있도록한다.
     */
    function burnFrom(address from, uint256 value) internal returns (bool) {
        require(value <= balances[from], "Your balance is insufficient.");

        balances[from] = balances[from].sub(value);
        totalSupply_ = totalSupply_.sub(value);

        emit Transfer(from, address(0), value);
        return true;
    }

    function drmBurnFrom(address from, uint256 value, string memory note) public onlyOwner returns (bool ret) {
        ret = burnFrom(from, value);
        emit DRMBurnFrom(msg.sender, from, value, note);
    }
    
    /**
     * dev DRM 팀에게 전송하는 경우
     */
    function drmTransferToTeam(
        address from,
        address to,
        uint256 value,
        string memory note
    ) public onlyOwner returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transferFrom(from, to, value);
        emit DRMTransferToTeam(from, msg.sender, to, value, note);
        return ret;
    }
    
    /**
     * dev 파트너(어드바이저)에게 전송하는 경우
     */
    function drmTransferToPartner(
        address from,
        address to,
        uint256 value,
        string memory note
    ) public onlyOwner returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transferFrom(from, to, value);
        emit DRMTransferToPartner(from, msg.sender, to, value, note);
    }

    /**
     * dev 보상을 DRM 지급
     * dev EOA가 트랜잭션을 일으켜서 처리 * 여러개 계좌를 기준으로 한다. (가스비 아끼기 위함)
     */
    function drmBatchTransferToEcosystem(
        address from, address[] memory to,
        uint256[] memory values,
        uint256 processIdHash,
        uint256[] memory userIdHash,
        string memory note
    ) public onlyOwner returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length, "The sizes of \'to\' and \'values\' arrays are different.");
        require(length == userIdHash.length, "The sizes of \'to\' and \'userIdHash\' arrays are different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of DoDreamChain.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit DRMTransferToEcosystem(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }
    
    function destroy() public onlyRoot {
        selfdestruct(msg.sender);
    }
   
}