pragma solidity 0.6.1;
pragma experimental ABIEncoderV2;

//import "./FundFactory.sol";
//import "./Hub.sol";
//import "./SelfDestructing.sol";
//import "./MaliciousToken.sol"; 
//import "./Registry.sol"; 
//import "./IKyberNetworkProxy.sol"; 
//import "./SafeMath.sol";
//import "./DSAuth.sol";
//import "./DSGuardEvents.sol";
//import "./DSMath.sol";
//import "./BurnableToken.sol";
//import "./IERC20.sol";
//import "./PreminedToken.sol";
//import "./StandardToken.sol";
//import "./TokenUser.sol";
//import "./WETH.sol";
//import "./AmguConsumer.sol";
//import "./Engine.sol";
//import "./IEngine.sol";
//import "./EngineAdapter.sol";
//import "./EthfinexAdapter.sol";
//import "./ExchangeAdapter.sol";
//import "./IWrapperLock.sol";
//import "./IOasisDex.sol";
//import "./IUniswapExchange.sol";
//import "./IUniswapFactory.sol";
//import "./IZeroExV2.sol";
//import "./IZeroExV3.sol";
//import "./KyberAdapter.sol";
//import "./OasisDexAccessor.sol";
//import "./OasisDexAdapter.sol";
//import "./UniswapAdapter.sol";
//import "./ZeroExV2Adapter.sol";
//import "./ZeroExV3Adapter.sol";
//import "./Factory.sol";
//import "./Accounting.sol";
//import "./IAccounting.sol";
//import "./FeeManager.sol";
//import "./IFee.sol";
//import "./IFeeManagerFactory.sol";
//import "./ManagementFee.sol";
//import "./PerformanceFee.sol";
//import "./Spoke.sol";
//import "./IParticipation.sol";
//import "./Participation.sol";
//import "./AddressList.sol";
//import "./UserWhitelist.sol";
//import "./IPolicy.sol";
//import "./IPolicyManagerFactory.sol";
//import "./PolicyManager.sol";
//import "./AssetBlacklist.sol";
//import "./AssetWhitelist.sol";
//import "./MaxConcentration.sol";
//import "./MaxPositions.sol";
//import "./PriceTolerance.sol";
//import "./TradingSignatures.sol";
//import "./IShares.sol";
//import "./Shares.sol";
//import "./ITrading.sol";
//import "./Trading.sol";
//import "./IVault.sol";
//import "./IPriceSource.sol";
//import "./KyberPriceFeed.sol";
//import "./IVersion.sol";
//import "./BooleanPolicy.sol";
//import "./MockAccounting.sol";
//import "./MockAdapter.sol";
//import "./MockFee.sol";
//import "./MockFeeManager.sol";
//import "./MockHub.sol";
//import "./MockRegistry.sol";
//import "./MockShares.sol";
//import "./MockVersion.sol";
//import "./PermissiveAuthority.sol";
//import "./estingPriceFeed.sol";

contract TestingPriceFeed is DSMath {
    event PriceUpdate(address[] token, uint[] price);

    struct Data {
        uint price;
        uint timestamp;
    }

    address public QUOTE_ASSET;
    uint public updateId;
    uint public lastUpdate;
    mapping(address => Data) public assetsToPrices;
    mapping(address => uint) public assetsToDecimals;
    bool mockIsRecent = true;
    bool neverValid = false;

    constructor(address _quoteAsset, uint _quoteDecimals) public {
        QUOTE_ASSET = _quoteAsset;
        setDecimals(_quoteAsset, _quoteDecimals);
    }

    /**
      Input price is how much quote asset you would get
      for one unit of _asset (10**assetDecimals)
     */
    function update(address[] calldata _assets, uint[] calldata _prices) external {
        require(_assets.length == _prices.length, "Array lengths unequal");
        updateId++;
        for (uint i = 0; i < _assets.length; ++i) {
            assetsToPrices[_assets[i]] = Data({
                timestamp: block.timestamp,
                price: _prices[i]
            });
        }
        lastUpdate = block.timestamp;
        emit PriceUpdate(_assets, _prices);
    }

    function getPrice(address ofAsset)
        public
        view
        returns (uint price, uint timestamp)
    {
        Data storage data = assetsToPrices[ofAsset];
        return (data.price, data.timestamp);
    }

    function getPrices(address[] memory ofAssets)
        public
        view
        returns (uint[] memory, uint[] memory)
    {
        uint[] memory prices = new uint[](ofAssets.length);
        uint[] memory timestamps = new uint[](ofAssets.length);
        for (uint i; i < ofAssets.length; i++) {
            uint price;
            uint timestamp;
            (price, timestamp) = getPrice(ofAssets[i]);
            prices[i] = price;
            timestamps[i] = timestamp;
        }
        return (prices, timestamps);
    }

    function getPriceInfo(address ofAsset)
        public
        view
        returns (uint price, uint assetDecimals)
    {
        (price, ) = getPrice(ofAsset);
        assetDecimals = assetsToDecimals[ofAsset];
    }

    function getInvertedPriceInfo(address ofAsset)
        public
        view
        returns (uint invertedPrice, uint assetDecimals)
    {
        uint inputPrice;
        // inputPrice quoted in QUOTE_ASSET and multiplied by 10 ** assetDecimal
        (inputPrice, assetDecimals) = getPriceInfo(ofAsset);

        // outputPrice based in QUOTE_ASSET and multiplied by 10 ** quoteDecimal
        uint quoteDecimals = assetsToDecimals[QUOTE_ASSET];

        return (
            mul(
                10 ** uint(quoteDecimals),
                10 ** uint(assetDecimals)
            ) / inputPrice,
            quoteDecimals
        );
    }

    function setNeverValid(bool _state) public {
        neverValid = _state;
    }

    function setIsRecent(bool _state) public {
        mockIsRecent = _state;
    }

    // NB: not permissioned; anyone can change this in a test
    function setDecimals(address _asset, uint _decimal) public {
        assetsToDecimals[_asset] = _decimal;
    }

    // needed just to get decimals for prices
    function batchSetDecimals(address[] memory _assets, uint[] memory _decimals) public {
        require(_assets.length == _decimals.length, "Array lengths unequal");
        for (uint i = 0; i < _assets.length; i++) {
            setDecimals(_assets[i], _decimals[i]);
        }
    }

    function getReferencePriceInfo(address ofBase, address ofQuote)
        public
        view
        returns (uint referencePrice, uint decimal)
    {
        uint quoteDecimals = assetsToDecimals[ofQuote];

        bool bothValid = hasValidPrice(ofBase) && hasValidPrice(ofQuote);
        require(bothValid, "Price not valid");
        // Price of 1 unit for the pair of same asset
        if (ofBase == ofQuote) {
            return (10 ** uint(quoteDecimals), quoteDecimals);
        }

        referencePrice = mul(
            assetsToPrices[ofBase].price,
            10 ** uint(quoteDecimals)
        ) / assetsToPrices[ofQuote].price;

        return (referencePrice, quoteDecimals);
    }

    function getOrderPriceInfo(
        address sellAsset,
        uint sellQuantity,
        uint buyQuantity
    )
        public
        view
        returns (uint orderPrice)
    {
        return mul(buyQuantity, 10 ** uint(assetsToDecimals[sellAsset])) / sellQuantity;
    }

    /// @notice Doesn't check validity as TestingPriceFeed has no validity variable
    /// @param _asset Asset in registrar
    /// @return isValid Price information ofAsset is recent
    function hasValidPrice(address _asset)
        public
        view
        returns (bool isValid)
    {
        uint price;
        (price, ) = getPrice(_asset);

        return !neverValid && price != 0;
    }

    function hasValidPrices(address[] memory _assets)
        public
        view
        returns (bool)
    {
        for (uint i; i < _assets.length; i++) {
            if (!hasValidPrice(_assets[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice Checks whether data exists for a given asset pair
    /// @dev Prices are only upated against QUOTE_ASSET
    /// @param sellAsset Asset for which check to be done if data exists
    /// @param buyAsset Asset for which check to be done if data exists
    function existsPriceOnAssetPair(address sellAsset, address buyAsset)
        public
        view
        returns (bool isExistent)
    {
        return
            hasValidPrice(sellAsset) &&
            hasValidPrice(buyAsset);
    }

    function getLastUpdateId() public view returns (uint) { return updateId; }
    function getQuoteAsset() public view returns (address) { return QUOTE_ASSET; }

    /// @notice Get quantity of toAsset equal in value to given quantity of fromAsset
    function convertQuantity(
        uint fromAssetQuantity,
        address fromAsset,
        address toAsset
    )
        public
        view
        returns (uint)
    {
        uint fromAssetPrice;
        (fromAssetPrice,) = getReferencePriceInfo(fromAsset, toAsset);
        uint fromAssetDecimals = ERC20WithFields(fromAsset).decimals();
        return mul(
            fromAssetQuantity,
            fromAssetPrice
        ) / (10 ** uint(fromAssetDecimals));
    }

    function getLastUpdate() public view returns (uint) { return lastUpdate; }
}

/// @dev Useful for testing force-sending of funds
contract SelfDestructing {
    function bequeath(address payable _heir) public {
        selfdestruct(_heir);
    }

    receive() external payable {}
}

contract PermissiveAuthority is DSAuthority {
    function canCall(address src, address dst, bytes4 sig)
        public
        view
        override
        returns (bool)
    {
        return true;
    }
}

contract MockVersion {
    uint public amguPrice;
    bool public isShutDown;

    function setAmguPrice(uint _price) public { amguPrice = _price; }
    function securityShutDown() external { isShutDown = true; }
    function shutDownFund(address _hub) external { Hub(_hub).shutDownFund(); }
    function getShutDownStatus() external view returns (bool) {return isShutDown;}
    function getAmguPrice() public view returns (uint) { return amguPrice; }
}

contract MockShares is Spoke, StandardToken {
    string public symbol;
    string public name;
    uint8 public decimals;

    constructor(address _hub) public Spoke(_hub) {
        name = hub.name();
        symbol = "MOCK";
        decimals = 18;
    }

    function createFor(address who, uint amount) public {
        _mint(who, amount);
    }

    function destroyFor(address who, uint amount) public {
        _burn(who, amount);
    }

    function setBalanceFor(address who, uint newBalance) public {
        uint currentBalance = balances[who];
        if (currentBalance > newBalance) {
            destroyFor(who, currentBalance.sub(newBalance));
        } else if (balances[who] < newBalance) {
            createFor(who, newBalance.sub(currentBalance));
        }
    }
}

contract MockRegistry is DSAuth {

    bool public alwaysRegistered = true;
    bool public methodAllowed = true;

    address public priceSource;
    address public mlnToken;
    address public nativeAsset;
    address public engine;
    address public fundFactory;
    address[] public assets;
    uint public incentive;
    mapping (address => bool) public registered;
    mapping (address => bool) public fundExists;
    mapping (address => address) public exchangeForAdapter;
    mapping (address => bool) public takesCustodyForAdapter;


    function register(address _addr) public {
        registered[_addr] = true;
        assets.push(_addr);
    }

    function remove(address _addr) public {
        delete registered[_addr];
    }

    function assetIsRegistered(address _asset) public view returns (bool) {
        return alwaysRegistered || registered[_asset];
    }

    function exchangeAdapterIsRegistered(address _adapter) public view returns (bool) {
        return alwaysRegistered || registered[_adapter];
    }

    function registerExchangeAdapter(
        address _exchange,
        address _adapter
    ) public {
        exchangeForAdapter[_adapter] = _exchange;
        takesCustodyForAdapter[_adapter] = true;
    }

    function adapterMethodIsAllowed(
        address _adapter,
        bytes4 _sig
    ) public view returns (bool) { return methodAllowed; }

    function setPriceSource(address _a) public { priceSource = _a; }
    function setMlnToken(address _a) public { mlnToken = _a; }
    function setNativeAsset(address _a) public { nativeAsset = _a; }
    function setEngine(address _a) public { engine = _a; }
    function setFundFactory(address _a) public { fundFactory = _a; }
    function setIsFund(address _who) public { fundExists[_who] = true; }

    function isFund(address _who) public view returns (bool) { return fundExists[_who]; }
    function isFundFactory(address _who) public view returns (bool) {
        return _who == fundFactory;
    }
    function getRegisteredAssets() public view returns (address[] memory) { return assets; }
    function getReserveMin(address _asset) public view returns (uint) { return 0; }
    function isFeeRegistered(address _fee) public view returns (bool) {
        return alwaysRegistered;
    }
    function getExchangeInformation(address _adapter)
        public
        view
        returns (address, bool)
    {
        return (
            exchangeForAdapter[_adapter],
            takesCustodyForAdapter[_adapter]
        );
    }
}

contract MockHub is DSGuard {

    struct Routes {
        address accounting;
        address feeManager;
        address participation;
        address policyManager;
        address shares;
        address trading;
        address vault;
        address registry;
        address version;
        address engine;
        address mlnAddress;
    }
    Routes public routes;
    address public manager;
    string public name;
    bool public isShutDown;

    function setManager(address _manager) public { manager = _manager; }

    function setName(string memory _name) public { name = _name; }

    function shutDownFund() public { isShutDown = true; }

    function setShutDownState(bool _state) public { isShutDown = _state; }

    function setSpokes(address[11] memory _spokes) public {
        routes.accounting = _spokes[0];
        routes.feeManager = _spokes[1];
        routes.participation = _spokes[2];
        routes.policyManager = _spokes[3];
        routes.shares = _spokes[4];
        routes.trading = _spokes[5];
        routes.vault = _spokes[6];
        routes.registry = _spokes[7];
        routes.version = _spokes[8];
        routes.engine = _spokes[9];
        routes.mlnAddress = _spokes[10];
    }

    function setRouting() public {
        address[11] memory spokes = [
            routes.accounting, routes.feeManager, routes.participation,
            routes.policyManager, routes.shares, routes.trading,
            routes.vault, routes.registry, routes.version,
            routes.engine, routes.mlnAddress
        ];
        Spoke(routes.accounting).initialize(spokes);
        Spoke(routes.feeManager).initialize(spokes);
        Spoke(routes.participation).initialize(spokes);
        Spoke(routes.policyManager).initialize(spokes);
        Spoke(routes.shares).initialize(spokes);
        Spoke(routes.trading).initialize(spokes);
        Spoke(routes.vault).initialize(spokes);
    }

    function setPermissions() public {
        permit(routes.participation, routes.vault, bytes4(keccak256('withdraw(address,uint256)')));
        permit(routes.trading, routes.vault, bytes4(keccak256('withdraw(address,uint256)')));
        permit(routes.participation, routes.shares, bytes4(keccak256('createFor(address,uint256)')));
        permit(routes.participation, routes.shares, bytes4(keccak256('destroyFor(address,uint256)')));
        permit(routes.feeManager, routes.shares, bytes4(keccak256('createFor(address,uint256)')));
        permit(routes.participation, routes.accounting, bytes4(keccak256('addAssetToOwnedAssets(address)')));
        permit(routes.participation, routes.accounting, bytes4(keccak256('removeFromOwnedAssets(address)')));
        permit(routes.trading, routes.accounting, bytes4(keccak256('addAssetToOwnedAssets(address)')));
        permit(routes.trading, routes.accounting, bytes4(keccak256('removeFromOwnedAssets(address)')));
        permit(routes.accounting, routes.feeManager, bytes4(keccak256('rewardAllFees()')));
        permit(manager, routes.feeManager, bytes4(keccak256('register(address)')));
        permit(manager, routes.feeManager, bytes4(keccak256('batchRegister(address[])')));
        permit(manager, routes.policyManager, bytes4(keccak256('register(bytes4,address)')));
        permit(manager, routes.policyManager, bytes4(keccak256('batchRegister(bytes4[],address[])')));
        permit(manager, routes.participation, bytes4(keccak256('enableInvestment(address[])')));
        permit(manager, routes.participation, bytes4(keccak256('disableInvestment(address[])')));
        permit(bytes32(bytes20(msg.sender)), ANY, ANY);
    }

    function permitSomething(address _from, address _to, bytes4 _sig) public {
        permit(
            bytes32(bytes20(_from)),
            bytes32(bytes20(_to)),
            _sig
        );
    }

    function initializeSpoke(address _spoke) public {
        address[11] memory spokes = [
            routes.accounting, routes.feeManager, routes.participation,
            routes.policyManager, routes.shares, routes.trading,
            routes.vault, routes.registry, routes.version,
            routes.engine, routes.mlnAddress
        ];
        Spoke(_spoke).initialize(spokes);
    }

    function vault() public view returns (address) { return routes.vault; }
    function accounting() public view returns (address) { return routes.accounting; }
    function priceSource() public view returns (address) { return Registry(routes.registry).priceSource(); }
    function participation() public view returns (address) { return routes.participation; }
    function trading() public view returns (address) { return routes.trading; }
    function shares() public view returns (address) { return routes.shares; }
    function policyManager() public view returns (address) { return routes.policyManager; }
    function registry() public view returns (address) { return routes.registry; }
}

contract MockFeeManager is DSMath, Spoke, AmguConsumer {

    struct FeeInfo {
        address feeAddress;
        uint feeRate;
        uint feePeriod;
    }

    uint totalFees;
    uint performanceFees;

    constructor(
        address _hub,
        address _denominationAsset,
        address[] memory _fees,
        uint[] memory _periods,
        uint _rates,
        address registry
    ) Spoke(_hub) public {}

    function setTotalFeeAmount(uint _amt) public { totalFees = _amt; }
    function setPerformanceFeeAmount(uint _amt) public { performanceFees = _amt; }

    function rewardManagementFee() public { return; }
    function performanceFeeAmount() external returns (uint) { return performanceFees; }
    function totalFeeAmount() external returns (uint) { return totalFees; }
    function engine() public view override(AmguConsumer, Spoke) returns (address) { return routes.engine; }
    function mlnToken() public view override(AmguConsumer, Spoke) returns (address) { return routes.mlnToken; }
    function priceSource() public view override(AmguConsumer, Spoke) returns (address) { return hub.priceSource(); }
    function registry() public view override(AmguConsumer, Spoke) returns (address) { return routes.registry; }
}

contract MockFee {

    uint public fee;
    uint public FEE_RATE;
    uint public FEE_PERIOD;
    uint public feeNumber;

    constructor(uint _feeNumber) public {
        feeNumber = _feeNumber;
    }

    function setFeeAmount(uint amount) public {
        fee = amount;
    }

    function feeAmount() external returns (uint feeInShares) {
        return fee;
    }

    function initializeForUser(uint feeRate, uint feePeriod, address denominationAsset) external {
        fee = 0;
        FEE_RATE = feeRate;
        FEE_PERIOD = feePeriod;
    }

    function updateState() external {
        fee = 0;
    }

    function identifier() external view returns (uint) {
        return feeNumber;
    }
}

contract MockAdapter is ExchangeAdapter {

    //  METHODS

    //  PUBLIC METHODS

    /// @notice Mock make order
    function makeOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public override {
        address makerAsset = orderAddresses[2];
        address takerAsset = orderAddresses[3];
        uint makerQuantity = orderValues[0];
        uint takerQuantity = orderValues[1];

        approveAsset(makerAsset, targetExchange, makerQuantity, "makerAsset");

        getTrading().orderUpdateHook(
            targetExchange,
            identifier,
            Trading.UpdateType.make,
            [payable(makerAsset), payable(takerAsset)],
            [makerQuantity, takerQuantity, uint(0)]
        );
        getTrading().addOpenMakeOrder(targetExchange, makerAsset, takerAsset, address(0), uint(identifier), 0);
    }

    /// @notice Mock take order
    function takeOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public override {
        address makerAsset = orderAddresses[2];
        address takerAsset = orderAddresses[3];
        uint makerQuantity = orderValues[0];
        uint takerQuantity = orderValues[1];
        uint fillTakerQuantity = orderValues[6];

        approveAsset(takerAsset, targetExchange, fillTakerQuantity, "takerAsset");

        getTrading().orderUpdateHook(
            targetExchange,
            bytes32(identifier),
            Trading.UpdateType.take,
            [payable(makerAsset), payable(takerAsset)],
            [makerQuantity, takerQuantity, fillTakerQuantity]
        );
    }

    /// @notice Mock cancel order
    function cancelOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public override {
        address makerAsset = orderAddresses[2];
        uint makerQuantity = orderValues[0];

        revokeApproveAsset(makerAsset, targetExchange, makerQuantity, "makerAsset");

        getTrading().removeOpenMakeOrder(targetExchange, makerAsset);
        getTrading().orderUpdateHook(
            targetExchange,
            bytes32(identifier),
            Trading.UpdateType.cancel,
            [address(0), address(0)],
            [uint(0), uint(0), uint(0)]
        );
    }
}

contract MockAccounting is Spoke {

    uint public gav;
    uint public nav;
    uint public unclaimedFees;
    uint public mockValuePerShare;

    address[] public ownedAssets;
    mapping (address => bool) public isInAssetList;
    mapping (address => uint) public held; // mock total held across all components
    mapping (address => uint) public assetGav;
    address public DENOMINATION_ASSET;
    address public NATIVE_ASSET;
    uint public DEFAULT_SHARE_PRICE;
    uint public SHARES_DECIMALS;

    constructor(address _hub, address _denominationAsset, address _nativeAsset)
        public
        Spoke(_hub)
    {
        DENOMINATION_ASSET = _denominationAsset;
        NATIVE_ASSET = _nativeAsset;
        SHARES_DECIMALS = 18;
        DEFAULT_SHARE_PRICE = 10 ** uint(SHARES_DECIMALS);
    }

    function setOwnedAssets(address[] memory _assets) public { ownedAssets = _assets; }
    function getOwnedAssetsLength() public view returns (uint) { return ownedAssets.length; }
    function setGav(uint _gav) public { gav = _gav; }
    function setNav(uint _nav) public { nav = _nav; }
    function setAssetGAV(address _asset, uint _amt) public { assetGav[_asset] = _amt; }
    function setFundHoldings(uint[] memory _amounts, address[] memory _assets) public {
        for (uint i = 0; i < _assets.length; i++) {
            held[_assets[i]] = _amounts[i];
        }
    }

    function getFundHoldings() public view returns (uint[] memory, address[] memory) {
        uint[] memory _quantities = new uint[](ownedAssets.length);
        address[] memory _assets = new address[](ownedAssets.length);
        for (uint i = 0; i < ownedAssets.length; i++) {
            address ofAsset = ownedAssets[i];
            // holdings formatting: mul(exchangeHoldings, 10 ** assetDecimal)
            uint quantityHeld = held[ofAsset];

            if (quantityHeld != 0) {
                _assets[i] = ofAsset;
                _quantities[i] = quantityHeld;
            }
        }
        return (_quantities, _assets);
    }

    function calcGav() public view returns (uint) { return gav; }
    function calcNav() public view returns (uint) { return nav; }

    function calcAssetGAV(address _a) public view returns (uint) { return assetGav[_a]; }

    function valuePerShare(uint totalValue, uint numShares) public view returns (uint) {
        return mockValuePerShare;
    }

    function performCalculations() public view returns (uint, uint, uint, uint, uint) {
        return (gav, unclaimedFees, 0, nav, mockValuePerShare);
    }
}

contract MaliciousToken is PreminedToken {

    bool public isReverting = false;

    constructor(string memory _symbol, uint8 _decimals, string memory _name)
        public
        PreminedToken(_symbol, _decimals, _name)
    {}

    function startReverting() public {
        isReverting = true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(!isReverting, "I'm afraid I can't do that, Dave");
        super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        override
        returns (bool)
    {
        require(!isReverting, "I'm afraid I can't do that, Dave");
        super.transferFrom(_from, _to, _value);
    }
}

contract BooleanPolicy {
    enum Applied { pre, post }

    bool allowed;

    function rule(bytes4 sig, address[5] calldata addresses, uint[3] calldata values, bytes32 identifier) external returns (bool) {
        return allowed;
    }

    function position() external pure returns (Applied) { return Applied.pre; }
}

contract TruePolicy is BooleanPolicy {
    constructor() public { allowed = true; }
    function identifier() external pure returns (string memory) { return "TruePolicy"; }
}

contract FalsePolicy is BooleanPolicy {
    constructor() public { allowed = false; }
    function identifier() external pure returns (string memory) { return "FalsePolicy"; }
}

contract Registry is DSAuth {

    // EVENTS
    event AssetUpsert (
        address indexed asset,
        string name,
        string symbol,
        uint decimals,
        string url,
        uint reserveMin,
        uint[] standards,
        bytes4[] sigs
    );

    event ExchangeAdapterUpsert (
        address indexed exchange,
        address indexed adapter,
        bool takesCustody,
        bytes4[] sigs
    );

    event AssetRemoval (address indexed asset);
    event EfxWrapperRegistryChange(address indexed registry);
    event EngineChange(address indexed engine);
    event ExchangeAdapterRemoval (address indexed exchange);
    event IncentiveChange(uint incentiveAmount);
    event MGMChange(address indexed MGM);
    event MlnTokenChange(address indexed mlnToken);
    event NativeAssetChange(address indexed nativeAsset);
    event PriceSourceChange(address indexed priceSource);
    event VersionRegistration(address indexed version);

    // TYPES
    struct Asset {
        bool exists;
        string name;
        string symbol;
        uint decimals;
        string url;
        uint reserveMin;
        uint[] standards;
        bytes4[] sigs;
    }

    struct Exchange {
        bool exists;
        address exchangeAddress;
        bool takesCustody;
        bytes4[] sigs;
    }

    struct Version {
        bool exists;
        bytes32 name;
    }

    // CONSTANTS
    uint public constant MAX_REGISTERED_ENTITIES = 20;
    uint public constant MAX_FUND_NAME_BYTES = 66;

    // FIELDS
    mapping (address => Asset) public assetInformation;
    address[] public registeredAssets;

    // Mapping from adapter address to exchange Information (Adapters are unique)
    mapping (address => Exchange) public exchangeInformation;
    address[] public registeredExchangeAdapters;

    mapping (address => Version) public versionInformation;
    address[] public registeredVersions;

    mapping (address => bool) public isFeeRegistered;

    mapping (address => address) public fundsToVersions;
    mapping (bytes32 => bool) public versionNameExists;
    mapping (bytes32 => address) public fundNameHashToOwner;


    uint public incentive = 10 finney;
    address public priceSource;
    address public mlnToken;
    address public nativeAsset;
    address public engine;
    address public ethfinexWrapperRegistry;
    address public MGM;

    modifier onlyVersion() {
        require(
            versionInformation[msg.sender].exists,
            "Only a Version can do this"
        );
        _;
    }

    // METHODS

    constructor(address _postDeployOwner) public {
        setOwner(_postDeployOwner);
    }

    // PUBLIC METHODS

    /// @notice Whether _name has only valid characters
    function isValidFundName(string memory _name) public pure returns (bool) {
        bytes memory b = bytes(_name);
        if (b.length > MAX_FUND_NAME_BYTES) return false;
        for (uint i; i < b.length; i++){
            bytes1 char = b[i];
            if(
                !(char >= 0x30 && char <= 0x39) && // 9-0
                !(char >= 0x41 && char <= 0x5A) && // A-Z
                !(char >= 0x61 && char <= 0x7A) && // a-z
                !(char == 0x20 || char == 0x2D) && // space, dash
                !(char == 0x2E || char == 0x5F) && // period, underscore
                !(char == 0x2A) // *
            ) {
                return false;
            }
        }
        return true;
    }

    /// @notice Whether _user can use _name for their fund
    function canUseFundName(address _user, string memory _name) public view returns (bool) {
        bytes32 nameHash = keccak256(bytes(_name));
        return (
            isValidFundName(_name) &&
            (
                fundNameHashToOwner[nameHash] == address(0) ||
                fundNameHashToOwner[nameHash] == _user
            )
        );
    }

    function reserveFundName(address _owner, string calldata _name)
        external
        onlyVersion
    {
        require(canUseFundName(_owner, _name), "Fund name cannot be used");
        fundNameHashToOwner[keccak256(bytes(_name))] = _owner;
    }

    function registerFund(address _fund, address _owner, string calldata _name)
        external
        onlyVersion
    {
        require(canUseFundName(_owner, _name), "Fund name cannot be used");
        fundsToVersions[_fund] = msg.sender;
    }

    /// @notice Registers an Asset information entry
    /// @dev Pre: Only registrar owner should be able to register
    /// @dev Post: Address _asset is registered
    /// @param _asset Address of asset to be registered
    /// @param _name Human-readable name of the Asset
    /// @param _symbol Human-readable symbol of the Asset
    /// @param _url Url for extended information of the asset
    /// @param _standards Integers of EIP standards this asset adheres to
    /// @param _sigs Function signatures for whitelisted asset functions
    function registerAsset(
        address _asset,
        string calldata _name,
        string calldata _symbol,
        string calldata _url,
        uint _reserveMin,
        uint[] calldata _standards,
        bytes4[] calldata _sigs
    ) external auth {
        require(registeredAssets.length < MAX_REGISTERED_ENTITIES);
        require(!assetInformation[_asset].exists);
        assetInformation[_asset].exists = true;
        registeredAssets.push(_asset);
        updateAsset(
            _asset,
            _name,
            _symbol,
            _url,
            _reserveMin,
            _standards,
            _sigs
        );
    }

    /// @notice Register an exchange information entry (A mapping from exchange adapter -> Exchange information)
    /// @dev Adapters are unique so are used as the mapping key. There may be different adapters for same exchange (0x / Ethfinex)
    /// @dev Pre: Only registrar owner should be able to register
    /// @dev Post: Address _exchange is registered
    /// @param _exchange Address of the exchange for the adapter
    /// @param _adapter Address of exchange adapter
    /// @param _takesCustody Whether this exchange takes custody of tokens before trading
    /// @param _sigs Function signatures for whitelisted exchange functions
    function registerExchangeAdapter(
        address _exchange,
        address _adapter,
        bool _takesCustody,
        bytes4[] calldata _sigs
    ) external auth {
        require(!exchangeInformation[_adapter].exists, "Adapter already exists");
        exchangeInformation[_adapter].exists = true;
        require(registeredExchangeAdapters.length < MAX_REGISTERED_ENTITIES, "Exchange limit reached");
        registeredExchangeAdapters.push(_adapter);
        updateExchangeAdapter(
            _exchange,
            _adapter,
            _takesCustody,
            _sigs
        );
    }

    /// @notice Versions cannot be removed from registry
    /// @param _version Address of the version contract
    /// @param _name Name of the version
    function registerVersion(
        address _version,
        bytes32 _name
    ) external auth {
        require(!versionInformation[_version].exists, "Version already exists");
        require(!versionNameExists[_name], "Version name already exists");
        versionInformation[_version].exists = true;
        versionNameExists[_name] = true;
        versionInformation[_version].name = _name;
        registeredVersions.push(_version);
        emit VersionRegistration(_version);
    }

    function setIncentive(uint _weiAmount) external auth {
        incentive = _weiAmount;
        emit IncentiveChange(_weiAmount);
    }

    function setPriceSource(address _priceSource) external auth {
        priceSource = _priceSource;
        emit PriceSourceChange(_priceSource);
    }

    function setMlnToken(address _mlnToken) external auth {
        mlnToken = _mlnToken;
        emit MlnTokenChange(_mlnToken);
    }

    function setNativeAsset(address _nativeAsset) external auth {
        nativeAsset = _nativeAsset;
        emit NativeAssetChange(_nativeAsset);
    }

    function setEngine(address _engine) external auth {
        engine = _engine;
        emit EngineChange(_engine);
    }

    function setMGM(address _MGM) external auth {
        MGM = _MGM;
        emit MGMChange(_MGM);
    }

    function setEthfinexWrapperRegistry(address _registry) external auth {
        ethfinexWrapperRegistry = _registry;
        emit EfxWrapperRegistryChange(_registry);
    }

    /// @notice Updates description information of a registered Asset
    /// @dev Pre: Owner can change an existing entry
    /// @dev Post: Changed Name, Symbol, URL and/or IPFSHash
    /// @param _asset Address of the asset to be updated
    /// @param _name Human-readable name of the Asset
    /// @param _symbol Human-readable symbol of the Asset
    /// @param _url Url for extended information of the asset
    function updateAsset(
        address _asset,
        string memory _name,
        string memory _symbol,
        string memory _url,
        uint _reserveMin,
        uint[] memory _standards,
        bytes4[] memory _sigs
    ) public auth {
        require(assetInformation[_asset].exists);
        Asset storage asset = assetInformation[_asset];
        asset.name = _name;
        asset.symbol = _symbol;
        asset.decimals = ERC20WithFields(_asset).decimals();
        asset.url = _url;
        asset.reserveMin = _reserveMin;
        asset.standards = _standards;
        asset.sigs = _sigs;
        emit AssetUpsert(
            _asset,
            _name,
            _symbol,
            asset.decimals,
            _url,
            _reserveMin,
            _standards,
            _sigs
        );
    }

    function updateExchangeAdapter(
        address _exchange,
        address _adapter,
        bool _takesCustody,
        bytes4[] memory _sigs
    ) public auth {
        require(exchangeInformation[_adapter].exists, "Exchange with adapter doesn't exist");
        Exchange storage exchange = exchangeInformation[_adapter];
        exchange.exchangeAddress = _exchange;
        exchange.takesCustody = _takesCustody;
        exchange.sigs = _sigs;
        emit ExchangeAdapterUpsert(
            _exchange,
            _adapter,
            _takesCustody,
            _sigs
        );
    }

    /// @notice Deletes an existing entry
    /// @dev Owner can delete an existing entry
    /// @param _asset address for which specific information is requested
    function removeAsset(
        address _asset,
        uint _assetIndex
    ) external auth {
        require(assetInformation[_asset].exists);
        require(registeredAssets[_assetIndex] == _asset);
        delete assetInformation[_asset];
        delete registeredAssets[_assetIndex];
        for (uint i = _assetIndex; i < registeredAssets.length-1; i++) {
            registeredAssets[i] = registeredAssets[i+1];
        }
        registeredAssets.pop();
        emit AssetRemoval(_asset);
    }

    /// @notice Deletes an existing entry
    /// @dev Owner can delete an existing entry
    /// @param _adapter address of the adapter of the exchange that is to be removed
    /// @param _adapterIndex index of the exchange in array
    function removeExchangeAdapter(
        address _adapter,
        uint _adapterIndex
    ) external auth {
        require(exchangeInformation[_adapter].exists, "Exchange with adapter doesn't exist");
        require(registeredExchangeAdapters[_adapterIndex] == _adapter, "Incorrect adapter index");
        delete exchangeInformation[_adapter];
        delete registeredExchangeAdapters[_adapterIndex];
        for (uint i = _adapterIndex; i < registeredExchangeAdapters.length-1; i++) {
            registeredExchangeAdapters[i] = registeredExchangeAdapters[i+1];
        }
        registeredExchangeAdapters.pop();
        emit ExchangeAdapterRemoval(_adapter);
    }

    function registerFees(address[] calldata _fees) external auth {
        for (uint i; i < _fees.length; i++) {
            isFeeRegistered[_fees[i]] = true;
        }
    }

    function deregisterFees(address[] calldata _fees) external auth {
        for (uint i; i < _fees.length; i++) {
            delete isFeeRegistered[_fees[i]];
        }
    }

    // PUBLIC VIEW METHODS

    // get asset specific information
    function getName(address _asset) external view returns (string memory) {
        return assetInformation[_asset].name;
    }
    function getSymbol(address _asset) external view returns (string memory) {
        return assetInformation[_asset].symbol;
    }
    function getDecimals(address _asset) external view returns (uint) {
        return assetInformation[_asset].decimals;
    }
    function getReserveMin(address _asset) external view returns (uint) {
        return assetInformation[_asset].reserveMin;
    }
    function assetIsRegistered(address _asset) external view returns (bool) {
        return assetInformation[_asset].exists;
    }
    function getRegisteredAssets() external view returns (address[] memory) {
        return registeredAssets;
    }
    function assetMethodIsAllowed(address _asset, bytes4 _sig)
        external
        view
        returns (bool)
    {
        bytes4[] memory signatures = assetInformation[_asset].sigs;
        for (uint i = 0; i < signatures.length; i++) {
            if (signatures[i] == _sig) {
                return true;
            }
        }
        return false;
    }

    // get exchange-specific information
    function exchangeAdapterIsRegistered(address _adapter) external view returns (bool) {
        return exchangeInformation[_adapter].exists;
    }
    function getRegisteredExchangeAdapters() external view returns (address[] memory) {
        return registeredExchangeAdapters;
    }
    function getExchangeInformation(address _adapter)
        public
        view
        returns (address, bool)
    {
        Exchange memory exchange = exchangeInformation[_adapter];
        return (
            exchange.exchangeAddress,
            exchange.takesCustody
        );
    }
    function exchangeForAdapter(address _adapter) external view returns (address) {
        Exchange memory exchange = exchangeInformation[_adapter];
        return exchange.exchangeAddress;
    }
    function getAdapterFunctionSignatures(address _adapter)
        public
        view
        returns (bytes4[] memory)
    {
        return exchangeInformation[_adapter].sigs;
    }
    function adapterMethodIsAllowed(
        address _adapter, bytes4 _sig
    )
        external
        view
        returns (bool)
    {
        bytes4[] memory signatures = exchangeInformation[_adapter].sigs;
        for (uint i = 0; i < signatures.length; i++) {
            if (signatures[i] == _sig) {
                return true;
            }
        }
        return false;
    }

    // get version and fund information
    function getRegisteredVersions() external view returns (address[] memory) {
        return registeredVersions;
    }

    function isFund(address _who) external view returns (bool) {
        if (fundsToVersions[_who] != address(0)) {
            return true; // directly from a hub
        } else {
            Hub hub = Hub(Spoke(_who).hub());
            require(
                hub.isSpoke(_who),
                "Call from either a spoke or hub"
            );
            return fundsToVersions[address(hub)] != address(0);
        }
    }

    function isFundFactory(address _who) external view returns (bool) {
        return versionInformation[_who].exists;
    }
}

interface IVersion {
    function shutDownFund(address) external;
}

contract KyberPriceFeed is DSMath, DSAuth {
    event PriceUpdate(address[] token, uint[] price);

    address public KYBER_NETWORK_PROXY;
    address public QUOTE_ASSET;
    address public UPDATER;
    Registry public REGISTRY;
    uint public MAX_SPREAD;
    address public constant KYBER_ETH_TOKEN = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint public constant KYBER_PRECISION = 18;
    uint public constant VALIDITY_INTERVAL = 2 days;
    uint public lastUpdate;

    // FIELDS

    mapping (address => uint) public prices;

    // METHODS

    // CONSTRUCTOR

    /// @dev Define and register a quote asset against which all prices are measured/based against
    constructor(
        address ofRegistry,
        address ofKyberNetworkProxy,
        uint ofMaxSpread,
        address ofQuoteAsset,
        address initialUpdater
    )
        public
    {
        KYBER_NETWORK_PROXY = ofKyberNetworkProxy;
        MAX_SPREAD = ofMaxSpread;
        QUOTE_ASSET = ofQuoteAsset;
        REGISTRY = Registry(ofRegistry);
        UPDATER = initialUpdater;
    }

    /// @dev Stores zero as a convention for invalid price
    function update() external {
        require(
            msg.sender == REGISTRY.owner() || msg.sender == UPDATER,
            "Only registry owner or updater can call"
        );
        address[] memory assets = REGISTRY.getRegisteredAssets();
        uint[] memory newPrices = new uint[](assets.length);
        for (uint i; i < assets.length; i++) {
            bool isValid;
            uint price;
            if (assets[i] == QUOTE_ASSET) {
                isValid = true;
                price = 1 ether;
            } else {
                (isValid, price) = getKyberPrice(assets[i], QUOTE_ASSET);
            }
            newPrices[i] = isValid ? price : 0;
            prices[assets[i]] = newPrices[i];
        }
        lastUpdate = block.timestamp;
        emit PriceUpdate(assets, newPrices);
    }

    function setUpdater(address _updater) external {
        require(msg.sender == REGISTRY.owner(), "Only registry owner can set");
        UPDATER = _updater;
    }

    /// @notice _maxSpread becomes a percentage when divided by 10^18
    /// @notice (e.g. 10^17 becomes 10%)
    function setMaxSpread(uint _maxSpread) external {
        require(msg.sender == REGISTRY.owner(), "Only registry owner can set");
        MAX_SPREAD = _maxSpread;
    }

    // PUBLIC VIEW METHODS

    // FEED INFORMATION

    function getQuoteAsset() public view returns (address) { return QUOTE_ASSET; }

    // PRICES

    /**
    @notice Gets price of an asset multiplied by ten to the power of assetDecimals
    @dev Asset has been registered
    @param _asset Asset for which price should be returned
    @return price Price formatting: mul(exchangePrice, 10 ** decimal), to avoid floating numbers
    @return timestamp When the asset's price was updated
    }
    */
    function getPrice(address _asset)
        public
        view
        returns (uint price, uint timestamp)
    {
        (price, ) =  getReferencePriceInfo(_asset, QUOTE_ASSET);
        timestamp = now;
    }

    function getPrices(address[] memory _assets)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint[] memory newPrices = new uint[](_assets.length);
        uint[] memory timestamps = new uint[](_assets.length);
        for (uint i; i < _assets.length; i++) {
            (newPrices[i], timestamps[i]) = getPrice(_assets[i]);
        }
        return (newPrices, timestamps);
    }

    function hasValidPrice(address _asset)
        public
        view
        returns (bool)
    {
        bool isRegistered = REGISTRY.assetIsRegistered(_asset);
        bool isFresh = block.timestamp < add(lastUpdate, VALIDITY_INTERVAL);
        return prices[_asset] != 0 && isRegistered && isFresh;
    }

    function hasValidPrices(address[] memory _assets)
        public
        view
        returns (bool)
    {
        for (uint i; i < _assets.length; i++) {
            if (!hasValidPrice(_assets[i])) {
                return false;
            }
        }
        return true;
    }

    /**
    @param _baseAsset Address of base asset
    @param _quoteAsset Address of quote asset
    @return referencePrice Quantity of quoteAsset per whole baseAsset
    @return decimals Decimal places for quoteAsset
    }
    */
    function getReferencePriceInfo(address _baseAsset, address _quoteAsset)
        public
        view
        returns (uint referencePrice, uint decimals)
    {
        bool isValid;
        (
            isValid,
            referencePrice,
            decimals
        ) = getRawReferencePriceInfo(_baseAsset, _quoteAsset);
        require(isValid, "Price is not valid");
        return (referencePrice, decimals);
    }

    function getRawReferencePriceInfo(address _baseAsset, address _quoteAsset)
        public
        view
        returns (bool isValid, uint256 referencePrice, uint256 decimals)
    {
        isValid = hasValidPrice(_baseAsset) && hasValidPrice(_quoteAsset);
        uint256 quoteDecimals = ERC20WithFields(_quoteAsset).decimals();

        if (prices[_quoteAsset] == 0) {
            return (false, 0, 0);  // return early and avoid revert
        }

        referencePrice = mul(
            prices[_baseAsset],
            10 ** uint(quoteDecimals)
        ) / prices[_quoteAsset];

        return (isValid, referencePrice, quoteDecimals);
    }

    function getPriceInfo(address _asset)
        public
        view
        returns (uint256 price, uint256 assetDecimals)
    {
        return getReferencePriceInfo(_asset, QUOTE_ASSET);
    }

    /**
    @notice Gets inverted price of an asset
    @dev Asset has been initialised and its price is non-zero
    @param _asset Asset for which inverted price should be return
    @return invertedPrice Price based (instead of quoted) against QUOTE_ASSET
    @return assetDecimals Decimal places for this asset
    }
    */
    function getInvertedPriceInfo(address _asset)
        public
        view
        returns (uint256 invertedPrice, uint256 assetDecimals)
    {
        return getReferencePriceInfo(QUOTE_ASSET, _asset);
    }

    /// @dev Get Kyber representation of ETH if necessary
    function getKyberMaskAsset(address _asset) public view returns (address) {
        if (_asset == REGISTRY.nativeAsset()) {
            return KYBER_ETH_TOKEN;
        }
        return _asset;
    }

    /// @notice Returns validity and price from Kyber
    function getKyberPrice(address _baseAsset, address _quoteAsset)
        public
        view
        returns (bool, uint)
    {
        uint bidRate;
        uint bidRateOfReversePair;
        (bidRate,) = IKyberNetworkProxy(KYBER_NETWORK_PROXY).getExpectedRate(
            getKyberMaskAsset(_baseAsset),
            getKyberMaskAsset(_quoteAsset),
            REGISTRY.getReserveMin(_baseAsset)
        );
        (bidRateOfReversePair,) = IKyberNetworkProxy(KYBER_NETWORK_PROXY).getExpectedRate(
            getKyberMaskAsset(_quoteAsset),
            getKyberMaskAsset(_baseAsset),
            REGISTRY.getReserveMin(_quoteAsset)
        );

        if (bidRate == 0 || bidRateOfReversePair == 0) {
            return (false, 0);  // return early and avoid revert
        }

        uint askRate = 10 ** (KYBER_PRECISION * 2) / bidRateOfReversePair;
        /**
          Average the bid/ask prices:
          avgPriceFromKyber = (bidRate + askRate) / 2
          kyberPrice = (avgPriceFromKyber * 10^quoteDecimals) / 10^kyberPrecision
          or, rearranged:
          kyberPrice = ((bidRate + askRate) * 10^quoteDecimals) / 2 * 10^kyberPrecision
        */
        uint kyberPrice = mul(
            add(bidRate, askRate),
            10 ** uint(ERC20WithFields(_quoteAsset).decimals()) // use original quote decimals (not defined on mask)
        ) / mul(2, 10 ** uint(KYBER_PRECISION));

        // Find the "quoted spread", to inform caller whether it is below maximum
        uint spreadFromKyber;
        if (bidRate > askRate) {
            spreadFromKyber = 0; // crossed market condition
        } else {
            spreadFromKyber = mul(
                sub(askRate, bidRate),
                10 ** uint(KYBER_PRECISION)
            ) / askRate;
        }

        return (
            spreadFromKyber <= MAX_SPREAD && bidRate != 0 && askRate != 0,
            kyberPrice
        );
    }

    /// @notice Gets price of Order
    /// @param sellAsset Address of the asset to be sold
    /// @param sellQuantity Quantity in base units being sold of sellAsset
    /// @param buyQuantity Quantity in base units being bought of buyAsset
    /// @return orderPrice Price as determined by an order
    function getOrderPriceInfo(
        address sellAsset,
        uint sellQuantity,
        uint buyQuantity
    )
        public
        view
        returns (uint orderPrice)
    {
        // TODO: decimals
        return mul(buyQuantity, 10 ** uint(ERC20WithFields(sellAsset).decimals())) / sellQuantity;
    }

    /// @notice Checks whether data exists for a given asset pair
    /// @dev Prices are only upated against QUOTE_ASSET
    /// @param sellAsset Asset for which check to be done if data exists
    /// @param buyAsset Asset for which check to be done if data exists
    function existsPriceOnAssetPair(address sellAsset, address buyAsset)
        public
        view
        returns (bool)
    {
        return
            hasValidPrice(sellAsset) && // Is tradable asset (TODO cleaner) and datafeed delivering data
            hasValidPrice(buyAsset);
    }

    /// @notice Get quantity of toAsset equal in value to given quantity of fromAsset
    function convertQuantity(
        uint fromAssetQuantity,
        address fromAsset,
        address toAsset
    )
        public
        view
        returns (uint)
    {
        uint fromAssetPrice;
        (fromAssetPrice,) = getReferencePriceInfo(fromAsset, toAsset);
        uint fromAssetDecimals = ERC20WithFields(fromAsset).decimals();
        return mul(
            fromAssetQuantity,
            fromAssetPrice
        ) / (10 ** uint(fromAssetDecimals));
    }

    function getLastUpdate() public view returns (uint) { return lastUpdate; }
}

/// @notice Must return a value for an asset
interface IPriceSource {
    function getQuoteAsset() external view returns (address);
    function getLastUpdate() external view returns (uint);

    /// @notice Returns false if asset not applicable, or price not recent
    function hasValidPrice(address) external view returns (bool);
    function hasValidPrices(address[] calldata) external view returns (bool);

    /// @notice Return the last known price, and when it was issued
    function getPrice(address _asset) external view returns (uint price, uint timestamp);
    function getPrices(address[] calldata _assets) external view returns (uint[] memory prices, uint[] memory timestamps);

    /// @notice Get price info, and revert if not valid
    function getPriceInfo(address _asset) external view returns (uint price, uint decimals);
    function getInvertedPriceInfo(address ofAsset) external view returns (uint price, uint decimals);

    function getReferencePriceInfo(address _base, address _quote) external view returns (uint referencePrice, uint decimal);
    function getOrderPriceInfo(address sellAsset, uint sellQuantity, uint buyQuantity) external view returns (uint orderPrice);
    function existsPriceOnAssetPair(address sellAsset, address buyAsset) external view returns (bool isExistent);
    function convertQuantity(
        uint fromAssetQuantity,
        address fromAsset,
        address toAsset
    ) external view returns (uint);
}

/// @notice Dumb custody component
contract Vault is TokenUser, Spoke {

    constructor(address _hub) public Spoke(_hub) {}

    function withdraw(address token, uint amount) external auth {
        safeTransfer(token, msg.sender, amount);
    }
}

contract VaultFactory is Factory {
    function createInstance(address _hub) external returns (address) {
        address vault = address(new Vault(_hub));
        childExists[vault] = true;
        emit NewInstance(_hub, vault);
        return vault;
    }
}

/// @notice Custody component
interface IVault {
    function withdraw(address token, uint amount) external;
}

interface IVaultFactory {
    function createInstance(address _hub) external returns (address);
}

contract Trading is DSMath, TokenUser, Spoke, TradingSignatures {
    event ExchangeMethodCall(
        address indexed exchangeAddress,
        string indexed methodSignature,
        address[8] orderAddresses,
        uint[8] orderValues,
        bytes[4] orderData,
        bytes32 identifier,
        bytes signature
    );

    struct Exchange {
        address exchange;
        address adapter;
        bool takesCustody;
    }

    enum UpdateType { make, take, cancel }

    struct Order {
        address exchangeAddress;
        bytes32 orderId;
        UpdateType updateType;
        address makerAsset;
        address takerAsset;
        uint makerQuantity;
        uint takerQuantity;
        uint timestamp;
        uint fillTakerQuantity;
    }

    struct OpenMakeOrder {
        uint id; // Order Id from exchange
        uint expiresAt; // Timestamp when the order expires
        uint orderIndex; // Index of the order in the orders array
        address buyAsset; // Address of the buy asset in the order
        address feeAsset;
    }

    Exchange[] public exchanges;
    Order[] public orders;
    mapping (address => bool) public adapterIsAdded;
    mapping (address => mapping(address => OpenMakeOrder)) public exchangesToOpenMakeOrders;
    mapping (address => uint) public openMakeOrdersAgainstAsset;
    mapping (address => uint) public openMakeOrdersUsingAssetAsFee;
    mapping (address => bool) public isInOpenMakeOrder;
    mapping (address => uint) public makerAssetCooldown;
    mapping (bytes32 => IZeroExV2.Order) internal orderIdToZeroExV2Order;
    mapping (bytes32 => IZeroExV3.Order) internal orderIdToZeroExV3Order;

    uint public constant ORDER_LIFESPAN = 1 days;
    uint public constant MAKE_ORDER_COOLDOWN = 30 minutes;

    modifier delegateInternal() {
        require(msg.sender == address(this), "Sender is not this contract");
        _;
    }

    constructor(
        address _hub,
        address[] memory _exchanges,
        address[] memory _adapters,
        address _registry
    )
        public
        Spoke(_hub)
    {
        routes.registry = _registry;
        require(_exchanges.length == _adapters.length, "Array lengths unequal");
        for (uint i = 0; i < _exchanges.length; i++) {
            _addExchange(_exchanges[i], _adapters[i]);
        }
    }

    /// @notice Receive ether function (used to receive ETH from WETH)
    receive() external payable {}

    function addExchange(address _exchange, address _adapter) external auth {
        _addExchange(_exchange, _adapter);
    }

    function _addExchange(
        address _exchange,
        address _adapter
    ) internal {
        require(!adapterIsAdded[_adapter], "Adapter already added");
        adapterIsAdded[_adapter] = true;
        Registry registry = Registry(routes.registry);
        require(
            registry.exchangeAdapterIsRegistered(_adapter),
            "Adapter is not registered"
        );

        address registeredExchange;
        bool takesCustody;
        (registeredExchange, takesCustody) = registry.getExchangeInformation(_adapter);

        require(
            registeredExchange == _exchange,
            "Exchange and adapter do not match"
        );
        exchanges.push(Exchange(_exchange, _adapter, takesCustody));
    }

    /// @notice Universal method for calling exchange functions through adapters
    /// @notice See adapter contracts for parameters needed for each exchange
    /// @param exchangeIndex Index of the exchange in the "exchanges" array
    /// @param orderAddresses [0] Order maker
    /// @param orderAddresses [1] Order taker
    /// @param orderAddresses [2] Order maker asset
    /// @param orderAddresses [3] Order taker asset
    /// @param orderAddresses [4] feeRecipientAddress
    /// @param orderAddresses [5] senderAddress
    /// @param orderAddresses [6] maker fee asset
    /// @param orderAddresses [7] taker fee asset
    /// @param orderValues [0] makerAssetAmount
    /// @param orderValues [1] takerAssetAmount
    /// @param orderValues [2] Maker fee
    /// @param orderValues [3] Taker fee
    /// @param orderValues [4] expirationTimeSeconds
    /// @param orderValues [5] Salt/nonce
    /// @param orderValues [6] Fill amount: amount of taker token to be traded
    /// @param orderValues [7] Dexy signature mode
    /// @param orderData [0] Encoded data specific to maker asset
    /// @param orderData [1] Encoded data specific to taker asset
    /// @param orderData [2] Encoded data specific to maker asset fee
    /// @param orderData [3] Encoded data specific to taker asset fee
    /// @param identifier Order identifier
    /// @param signature Signature of order maker
    function callOnExchange(
        uint exchangeIndex,
        string memory methodSignature,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    )
        public
        onlyInitialized
    {
        bytes4 methodSelector = bytes4(keccak256(bytes(methodSignature)));
        require(
            Registry(routes.registry).adapterMethodIsAllowed(
                exchanges[exchangeIndex].adapter,
                methodSelector
            ),
            "Adapter method not allowed"
        );
        PolicyManager(routes.policyManager).preValidate(methodSelector, [orderAddresses[0], orderAddresses[1], orderAddresses[2], orderAddresses[3], exchanges[exchangeIndex].exchange], [orderValues[0], orderValues[1], orderValues[6]], identifier);
        if (
            methodSelector == MAKE_ORDER ||
            methodSelector == TAKE_ORDER
        ) {
            require(Registry(routes.registry).assetIsRegistered(
                orderAddresses[2]), 'Maker asset not registered'
            );
            require(Registry(routes.registry).assetIsRegistered(
                orderAddresses[3]), 'Taker asset not registered'
            );
            if (orderAddresses[6] != address(0) && methodSelector == MAKE_ORDER) {
                require(
                    Registry(routes.registry).assetIsRegistered(orderAddresses[6]),
                    'Maker fee asset not registered'
                );
            }
            if (orderAddresses[7] != address(0) && methodSelector == TAKE_ORDER) {
                require(
                    Registry(routes.registry).assetIsRegistered(orderAddresses[7]),
                    'Taker fee asset not registered'
                );
            }
        }
        (bool success, bytes memory returnData) = exchanges[exchangeIndex].adapter.delegatecall(
            abi.encodeWithSignature(
                methodSignature,
                exchanges[exchangeIndex].exchange,
                orderAddresses,
                orderValues,
                orderData,
                identifier,
                signature
            )
        );
        require(success, string(returnData));
        PolicyManager(routes.policyManager).postValidate(methodSelector, [orderAddresses[0], orderAddresses[1], orderAddresses[2], orderAddresses[3], exchanges[exchangeIndex].exchange], [orderValues[0], orderValues[1], orderValues[6]], identifier);
        emit ExchangeMethodCall(
            exchanges[exchangeIndex].exchange,
            methodSignature,
            orderAddresses,
            orderValues,
            orderData,
            identifier,
            signature
        );
    }

    /// @dev Make sure this is called after orderUpdateHook in adapters
    function addOpenMakeOrder(
        address ofExchange,
        address sellAsset,
        address buyAsset,
        address feeAsset,
        uint orderId,
        uint expirationTime
    ) public delegateInternal {
        require(!isInOpenMakeOrder[sellAsset], "Asset already in open order");
        require(orders.length > 0, "No orders in array");

        // If expirationTime is 0, actualExpirationTime is set to ORDER_LIFESPAN from now
        uint actualExpirationTime = (expirationTime == 0) ? add(block.timestamp, ORDER_LIFESPAN) : expirationTime;

        require(
            actualExpirationTime <= add(block.timestamp, ORDER_LIFESPAN) &&
            actualExpirationTime > block.timestamp,
            "Expiry time greater than max order lifespan or has already passed"
        );
        isInOpenMakeOrder[sellAsset] = true;
        makerAssetCooldown[sellAsset] = add(actualExpirationTime, MAKE_ORDER_COOLDOWN);
        openMakeOrdersAgainstAsset[buyAsset] = add(openMakeOrdersAgainstAsset[buyAsset], 1);
        if (feeAsset != address(0)) {
            openMakeOrdersUsingAssetAsFee[feeAsset] = add(openMakeOrdersUsingAssetAsFee[feeAsset], 1);
        }
        exchangesToOpenMakeOrders[ofExchange][sellAsset].id = orderId;
        exchangesToOpenMakeOrders[ofExchange][sellAsset].expiresAt = actualExpirationTime;
        exchangesToOpenMakeOrders[ofExchange][sellAsset].orderIndex = sub(orders.length, 1);
        exchangesToOpenMakeOrders[ofExchange][sellAsset].buyAsset = buyAsset;
    }

    function _removeOpenMakeOrder(
        address exchange,
        address sellAsset
    ) internal {
        if (isInOpenMakeOrder[sellAsset]) {
            makerAssetCooldown[sellAsset] = add(block.timestamp, MAKE_ORDER_COOLDOWN);
            address buyAsset = exchangesToOpenMakeOrders[exchange][sellAsset].buyAsset;
            address feeAsset = exchangesToOpenMakeOrders[exchange][sellAsset].feeAsset;
            delete exchangesToOpenMakeOrders[exchange][sellAsset];
            openMakeOrdersAgainstAsset[buyAsset] = sub(openMakeOrdersAgainstAsset[buyAsset], 1);
            if (feeAsset != address(0)) {
                openMakeOrdersUsingAssetAsFee[feeAsset] = sub(openMakeOrdersUsingAssetAsFee[feeAsset], 1);
            }
        }
    }

    function removeOpenMakeOrder(
        address exchange,
        address sellAsset
    ) public delegateInternal {
        _removeOpenMakeOrder(exchange, sellAsset);
    }

    /// @dev Bit of Redundancy for now
    function addZeroExV2OrderData(
        bytes32 orderId,
        IZeroExV2.Order memory zeroExOrderData
    ) public delegateInternal {
        orderIdToZeroExV2Order[orderId] = zeroExOrderData;
    }
    function addZeroExV3OrderData(
        bytes32 orderId,
        IZeroExV3.Order memory zeroExOrderData
    ) public delegateInternal {
        orderIdToZeroExV3Order[orderId] = zeroExOrderData;
    }

    function orderUpdateHook(
        address ofExchange,
        bytes32 orderId,
        UpdateType updateType,
        address payable[2] memory orderAddresses,
        uint[3] memory orderValues
    ) public delegateInternal {
        // only save make/take
        if (updateType == UpdateType.make || updateType == UpdateType.take) {
            orders.push(Order({
                exchangeAddress: ofExchange,
                orderId: orderId,
                updateType: updateType,
                makerAsset: orderAddresses[0],
                takerAsset: orderAddresses[1],
                makerQuantity: orderValues[0],
                takerQuantity: orderValues[1],
                timestamp: block.timestamp,
                fillTakerQuantity: orderValues[2]
            }));
        }
    }

    function updateAndGetQuantityBeingTraded(address _asset) external returns (uint) {
        uint quantityHere = IERC20(_asset).balanceOf(address(this));
        return add(updateAndGetQuantityHeldInExchange(_asset), quantityHere);
    }

    function updateAndGetQuantityHeldInExchange(address ofAsset) public returns (uint) {
        uint totalSellQuantity; // quantity in custody across exchanges
        uint totalSellQuantityInApprove; // quantity of asset in approve (allowance) but not custody of exchange
        for (uint i; i < exchanges.length; i++) {
            uint256 orderId = exchangesToOpenMakeOrders[exchanges[i].exchange][ofAsset].id;
            if (orderId == 0) {
                continue;
            }
            address sellAsset;
            uint remainingSellQuantity;
            (sellAsset, , remainingSellQuantity, ) =
                ExchangeAdapter(exchanges[i].adapter)
                .getOrder(
                    exchanges[i].exchange,
                    orderId,
                    ofAsset
                );
            if (remainingSellQuantity == 0) {    // remove id if remaining sell quantity zero (closed)
                _removeOpenMakeOrder(exchanges[i].exchange, ofAsset);
            }
            totalSellQuantity = add(totalSellQuantity, remainingSellQuantity);
            if (!exchanges[i].takesCustody) {
                totalSellQuantityInApprove += remainingSellQuantity;
            }
        }
        if (totalSellQuantity == 0) {
            isInOpenMakeOrder[ofAsset] = false;
        }
        return sub(totalSellQuantity, totalSellQuantityInApprove); // Since quantity in approve is not actually in custody
    }

    function returnBatchToVault(address[] calldata _tokens) external {
        for (uint i = 0; i < _tokens.length; i++) {
            returnAssetToVault(_tokens[i]);
        }
    }

    function returnAssetToVault(address _token) public {
        require(
            msg.sender == address(this) ||
            msg.sender == hub.manager() ||
            hub.isShutDown()            ||
            (!isInOpenMakeOrder[_token] && openMakeOrdersUsingAssetAsFee[_token] == 0),
            "returnAssetToVault: No return condition was met"
        );
        safeTransfer(_token, routes.vault, IERC20(_token).balanceOf(address(this)));
    }

    function getExchangeInfo() public view returns (address[] memory, address[] memory, bool[] memory) {
        address[] memory ofExchanges = new address[](exchanges.length);
        address[] memory ofAdapters = new address[](exchanges.length);
        bool[] memory takesCustody = new bool[](exchanges.length);
        for (uint i = 0; i < exchanges.length; i++) {
            ofExchanges[i] = exchanges[i].exchange;
            ofAdapters[i] = exchanges[i].adapter;
            takesCustody[i] = exchanges[i].takesCustody;
        }
        return (ofExchanges, ofAdapters, takesCustody);
    }

    function getOpenOrderInfo(address ofExchange, address ofAsset) public view returns (uint, uint, uint) {
        OpenMakeOrder memory order = exchangesToOpenMakeOrders[ofExchange][ofAsset];
        return (order.id, order.expiresAt, order.orderIndex);
    }

    function isOrderExpired(address exchange, address asset) public view returns(bool) {
        return (
            exchangesToOpenMakeOrders[exchange][asset].expiresAt <= block.timestamp &&
            exchangesToOpenMakeOrders[exchange][asset].expiresAt > 0
        );
    }

    function getOrderDetails(uint orderIndex) public view returns (address, address, uint, uint) {
        Order memory order = orders[orderIndex];
        return (order.makerAsset, order.takerAsset, order.makerQuantity, order.takerQuantity);
    }

    function getZeroExV2OrderDetails(bytes32 orderId) public view returns (IZeroExV2.Order memory) {
        return orderIdToZeroExV2Order[orderId];
    }

    function getZeroExV3OrderDetails(bytes32 orderId) public view returns (IZeroExV3.Order memory) {
        return orderIdToZeroExV3Order[orderId];
    }

    function getOpenMakeOrdersAgainstAsset(address _asset) external view returns (uint256) {
        return openMakeOrdersAgainstAsset[_asset];
    }
}

contract TradingFactory is Factory {
    event NewInstance(
        address indexed hub,
        address indexed instance,
        address[] exchanges,
        address[] adapters,
        address registry
    );

    function createInstance(
        address _hub,
        address[] memory _exchanges,
        address[] memory _adapters,
        address _registry
    ) public returns (address) {
        address trading = address(new Trading(_hub, _exchanges, _adapters, _registry));
        childExists[trading] = true;
        emit NewInstance(
            _hub,
            trading,
            _exchanges,
            _adapters,
            _registry
        );
        return trading;
    }
}

interface ITrading {
    function callOnExchange(
        uint exchangeIndex,
        string calldata methodSignature,
        address[8] calldata orderAddresses,
        uint[8] calldata orderValues,
        bytes[4] calldata orderData,
        bytes32 identifier,
        bytes calldata signature
    ) external;

    function addOpenMakeOrder(
        address ofExchange,
        address ofSellAsset,
        address ofBuyAsset,
        address ofFeeAsset,
        uint orderId,
        uint expiryTime
    ) external;

    function removeOpenMakeOrder(
        address ofExchange,
        address ofSellAsset
    ) external;

    function updateAndGetQuantityBeingTraded(address _asset) external returns (uint256);
    function getOpenMakeOrdersAgainstAsset(address _asset) external view returns (uint256);
}

interface ITradingFactory {
     function createInstance(
        address _hub,
        address[] calldata _exchanges,
        address[] calldata _adapters,
        address _registry
    ) external returns (address);
}

contract Shares is Spoke, StandardToken {
    string public symbol;
    string public name;
    uint8 public decimals;

    constructor(address _hub) public Spoke(_hub) {
        name = hub.name();
        symbol = "MLNF";
        decimals = 18;
    }

    function createFor(address who, uint amount) public auth {
        _mint(who, amount);
    }

    function destroyFor(address who, uint amount) public auth {
        _burn(who, amount);
    }

    function transfer(address to, uint amount) public override returns (bool) {
        revert("Unimplemented");
    }

    function transferFrom(
        address from,
        address to,
        uint amount
    )
        public
        override
        returns (bool)
    {
        revert("Unimplemented");
    }

    function approve(address spender, uint amount) public override returns (bool) {
        revert("Unimplemented");
    }

    function increaseApproval(
        address spender,
        uint amount
    )
        public
        override
        returns (bool)
    {
        revert("Unimplemented");
    }

    function decreaseApproval(
        address spender,
        uint amount
    )
        public
        override
        returns (bool)
    {
        revert("Unimplemented");
    }
}

contract SharesFactory is Factory {
    function createInstance(address _hub) external returns (address) {
        address shares = address(new Shares(_hub));
        childExists[shares] = true;
        emit NewInstance(_hub, shares);
        return shares;
    }
}

/// @notice Token representing ownership of the Fund
interface IShares {
    function createFor(address who, uint amount) external;
    function destroyFor(address who, uint amount) external;
}

interface ISharesFactory {
    function createInstance(address _hub) external returns (address);
}

contract TradingSignatures {
    bytes4 constant public MAKE_ORDER = 0x5f08e909; // makeOrderSignature
    bytes4 constant public TAKE_ORDER = 0x63b24ef1; // takeOrderSignature
}

contract PriceTolerance is TradingSignatures, DSMath {
    enum Applied { pre, post }

    uint256 public tolerance;

    uint256 constant MULTIPLIER = 10 ** 16; // to give effect of a percentage
    uint256 constant DIVISOR = 10 ** 18;

    // _tolerance: 10 equals to 10% of tolerance
    constructor(uint256 _tolerancePercent) public {
        require(_tolerancePercent <= 100, "Tolerance range is 0% - 100%");
        tolerance = mul(_tolerancePercent, MULTIPLIER);
    }

    /// @notice Taken from OpenZeppelin (https://git.io/fhQqo)
   function signedSafeSub(int256 _a, int256 _b) internal pure returns (int256) {
        int256 c = _a - _b;
        require((_b >= 0 && c <= _a) || (_b < 0 && c > _a));

        return c;
    }

    function checkPriceToleranceTakeOrder(
        address _makerAsset,
        address _takerAsset,
        uint256 _fillMakerQuantity,
        uint256 _fillTakerQuantity
    )
        internal
        view
        returns (bool)
    {
        IPriceSource pricefeed = IPriceSource(Hub(Trading(msg.sender).hub()).priceSource());
        uint256 referencePrice;
        (referencePrice,) = pricefeed.getReferencePriceInfo(_takerAsset, _makerAsset);

        uint256 orderPrice = pricefeed.getOrderPriceInfo(
            _takerAsset,
            _fillTakerQuantity,
            _fillMakerQuantity
        );

        return orderPrice >= sub(
            referencePrice,
            mul(tolerance, referencePrice) / DIVISOR
        );
    }

    function takeGenericOrder(
        address _makerAsset,
        address _takerAsset,
        uint256[3] memory _values
    ) public view returns (bool) {
        uint256 fillTakerQuantity = _values[2];
        uint256 fillMakerQuantity = mul(fillTakerQuantity, _values[0]) / _values[1];
        return checkPriceToleranceTakeOrder(
            _makerAsset, _takerAsset, fillMakerQuantity, fillTakerQuantity
        );
    }

    function takeOasisDex(
        address _exchange,
        bytes32 _identifier,
        uint256 _fillTakerQuantity
    ) public view returns (bool) {
        uint256 maxMakerQuantity;
        address makerAsset;
        uint256 maxTakerQuantity;
        address takerAsset;
        (
            maxMakerQuantity,
            makerAsset,
            maxTakerQuantity,
            takerAsset
        ) = IOasisDex(_exchange).getOffer(uint256(_identifier));

        uint256 fillMakerQuantity = mul(_fillTakerQuantity, maxMakerQuantity) / maxTakerQuantity;
        return checkPriceToleranceTakeOrder(
            makerAsset, takerAsset, fillMakerQuantity, _fillTakerQuantity
        );
    }

    function takeOrder(
        address[5] memory _addresses,
        uint256[3] memory _values,
        bytes32 _identifier
    ) public view returns (bool) {
        if (_identifier == 0x0) {
            return takeGenericOrder(_addresses[2], _addresses[3], _values);
        } else {
            return takeOasisDex(_addresses[4], _identifier, _values[2]);
        }
    }

    function makeOrder(
        address[5] memory _addresses,
        uint256[3] memory _values,
        bytes32 _identifier
    ) public view returns (bool) {
        IPriceSource pricefeed = IPriceSource(Hub(Trading(msg.sender).hub()).priceSource());

        uint256 ratio;
        (ratio,) = IPriceSource(pricefeed).getReferencePriceInfo(_addresses[2], _addresses[3]);
        uint256 value = IPriceSource(pricefeed).getOrderPriceInfo(_addresses[2], _values[0], _values[1]);

        int res = signedSafeSub(int(ratio), int(value));
        if (res < 0) {
            return true;
        } else {
            return wdiv(uint256(res), ratio) <= tolerance;
        }
    }

    function rule(
        bytes4 _sig,
        address[5] calldata _addresses,
        uint256[3] calldata _values,
        bytes32 _identifier
    ) external returns (bool) {
        if (_sig == MAKE_ORDER) {
            return makeOrder(_addresses, _values, _identifier);
        } else if (_sig == TAKE_ORDER) {
            return takeOrder(_addresses, _values, _identifier);
        }
        revert("Signature was neither MakeOrder nor TakeOrder");
    }

    function position() external pure returns (Applied) { return Applied.pre; }
    function identifier() external pure returns (string memory) { return 'PriceTolerance'; }
}

contract MaxPositions is TradingSignatures {
    enum Applied { pre, post }

    uint public maxPositions;

    /// @dev _maxPositions = 10 means max 10 different asset tokens
    /// @dev _maxPositions = 0 means no asset tokens are investable
    constructor(uint _maxPositions) public { maxPositions = _maxPositions; }

    function rule(bytes4 sig, address[5] calldata addresses, uint[3] calldata values, bytes32 identifier)
        external
        returns (bool)
    {
        Accounting accounting = Accounting(Hub(Trading(msg.sender).hub()).accounting());
        address denominationAsset = accounting.DENOMINATION_ASSET();
        // Always allow a trade INTO the quote asset
        address incomingToken = (sig == TAKE_ORDER) ? addresses[2] : addresses[3];
        if (denominationAsset == incomingToken) { return true; }
        return accounting.getOwnedAssetsLength() <= maxPositions;
    }

    function position() external pure returns (Applied) { return Applied.post; }
    function identifier() external pure returns (string memory) { return 'MaxPositions'; }
}

contract MaxConcentration is TradingSignatures, DSMath {
    enum Applied { pre, post }

    uint internal constant ONE_HUNDRED_PERCENT = 10 ** 18;  // 100%
    uint public maxConcentration;

    constructor(uint _maxConcentration) public {
        require(
            _maxConcentration <= ONE_HUNDRED_PERCENT,
            "Max concentration cannot exceed 100%"
        );
        maxConcentration = _maxConcentration;
    }

    function rule(bytes4 sig, address[5] calldata addresses, uint[3] calldata values, bytes32 identifier)
        external
        returns (bool)
    {
        Accounting accounting = Accounting(Hub(Trading(msg.sender).hub()).accounting());
        address denominationAsset = accounting.DENOMINATION_ASSET();
        // Max concentration is only checked for non-quote assets
        address takerToken = (sig == TAKE_ORDER) ? addresses[2] : addresses[3];
        if (denominationAsset == takerToken) { return true; }

        uint concentration;
        uint totalGav = accounting.calcGav();
        if (sig == MAKE_ORDER) {
            IPriceSource priceSource = IPriceSource(Hub(Trading(msg.sender).hub()).priceSource());
            address makerToken = addresses[2];
            uint makerQuantiyBeingTraded = values[0];
            uint takerQuantityBeingTraded = values[1];

            uint takerTokenGavBeingTraded = priceSource.convertQuantity(
                takerQuantityBeingTraded, takerToken, denominationAsset
            );

            uint makerTokenGavBeingTraded;
            if (makerToken == denominationAsset) {
                makerTokenGavBeingTraded = makerQuantiyBeingTraded;
            }
            else {
                makerTokenGavBeingTraded = priceSource.convertQuantity(
                    makerQuantiyBeingTraded, makerToken, denominationAsset
                );
            }
            concentration = _calcConcentration(
                add(accounting.calcAssetGAV(takerToken), takerTokenGavBeingTraded),
                add(takerTokenGavBeingTraded, sub(totalGav, makerTokenGavBeingTraded))
            );
        }
        else {
            concentration = _calcConcentration(
                accounting.calcAssetGAV(takerToken),
                totalGav
            );
        }
        return concentration <= maxConcentration;
    }

    function position() external pure returns (Applied) { return Applied.post; }
    function identifier() external pure returns (string memory) { return 'MaxConcentration'; }

    function _calcConcentration(uint assetGav, uint totalGav) internal returns (uint) {
        return mul(assetGav, ONE_HUNDRED_PERCENT) / totalGav;
    }
}

contract AssetWhitelist is TradingSignatures, AddressList {
    enum Applied { pre, post }

    constructor(address[] memory _assets) public AddressList(_assets) {}

    function removeFromWhitelist(address _asset) external auth {
        require(isMember(_asset), "Asset not in whitelist");
        delete list[_asset];
        uint i = getAssetIndex(_asset);
        for (i; i < mirror.length-1; i++){
            mirror[i] = mirror[i+1];
        }
        mirror.pop();
    }

    function getAssetIndex(address _asset) public view returns (uint) {
        for (uint i = 0; i < mirror.length; i++) {
            if (mirror[i] == _asset) { return i; }
        }
    }

    function rule(bytes4 sig, address[5] calldata addresses, uint[3] calldata values, bytes32 identifier) external returns (bool) {
        address incomingToken = (sig == TAKE_ORDER) ? addresses[2] : addresses[3];
        return isMember(incomingToken);
    }

    function position() external pure returns (Applied) { return Applied.pre; }
    function identifier() external pure returns (string memory) { return 'AssetWhitelist'; }
}

contract AssetBlacklist is TradingSignatures, AddressList {
    enum Applied { pre, post }

    // bytes4 constant public MAKE_ORDER = 0x79705be7; // makeOrderSignature
    // bytes4 constant public TAKE_ORDER = 0xe51be6e8; // takeOrderSignature

    constructor(address[] memory _assets) AddressList(_assets) public {}

    function addToBlacklist(address _asset) external auth {
        require(!isMember(_asset), "Asset already in blacklist");
        list[_asset] = true;
        mirror.push(_asset);
    }

    function rule(bytes4 sig, address[5] calldata addresses, uint[3] calldata values, bytes32 identifier) external returns (bool) {
        address incomingToken = (sig == TAKE_ORDER) ? addresses[2] : addresses[3];
        return !isMember(incomingToken);
    }

    function position() external pure returns (Applied) { return Applied.pre; }
    function identifier() external pure returns (string memory) { return 'AssetBlacklist'; }
}

contract PolicyManager is Spoke {

    event Registration(
        bytes4 indexed sig,
        IPolicy.Applied position,
        address indexed policy
    );

    struct Entry {
        IPolicy[] pre;
        IPolicy[] post;
    }

    mapping(bytes4 => Entry) policies;

    constructor (address _hub) public Spoke(_hub) {}

    function register(bytes4 sig, address _policy) public auth {
        IPolicy.Applied position = IPolicy(_policy).position();
        if (position == IPolicy.Applied.pre) {
            policies[sig].pre.push(IPolicy(_policy));
        } else if (position == IPolicy.Applied.post) {
            policies[sig].post.push(IPolicy(_policy));
        } else {
            revert("Only pre and post allowed");
        }
        emit Registration(sig, position, _policy);
    }

    function batchRegister(bytes4[] memory sig, address[] memory _policies) public auth {
        require(sig.length == _policies.length, "Arrays lengths unequal");
        for (uint i = 0; i < sig.length; i++) {
            register(sig[i], _policies[i]);
        }
    }

    function PoliciesToAddresses(IPolicy[] storage _policies) internal view returns (address[] memory) {
        address[] memory res = new address[](_policies.length);
        for(uint i = 0; i < _policies.length; i++) {
            res[i] = address(_policies[i]);
        }
        return res;
    }

    function getPoliciesBySig(bytes4 sig) public view returns (address[] memory, address[] memory) {
        return (PoliciesToAddresses(policies[sig].pre), PoliciesToAddresses(policies[sig].post));
    }

    modifier isValidPolicyBySig(bytes4 sig, address[5] memory addresses, uint[3] memory values, bytes32 identifier) {
        preValidate(sig, addresses, values, identifier);
        _;
        postValidate(sig, addresses, values, identifier);
    }

    modifier isValidPolicy(address[5] memory addresses, uint[3] memory values, bytes32 identifier) {
        preValidate(msg.sig, addresses, values, identifier);
        _;
        postValidate(msg.sig, addresses, values, identifier);
    }

    function preValidate(bytes4 sig, address[5] memory addresses, uint[3] memory values, bytes32 identifier) public {
        validate(policies[sig].pre, sig, addresses, values, identifier);
    }

    function postValidate(bytes4 sig, address[5] memory addresses, uint[3] memory values, bytes32 identifier) public {
        validate(policies[sig].post, sig, addresses, values, identifier);
    }

    function validate(IPolicy[] storage aux, bytes4 sig, address[5] memory addresses, uint[3] memory values, bytes32 identifier) internal {
        for(uint i = 0; i < aux.length; i++) {
            require(
                aux[i].rule(sig, addresses, values, identifier),
                string(abi.encodePacked("Rule evaluated to false: ", aux[i].identifier()))
            );
        }
    }
}

contract PolicyManagerFactory is Factory {
    function createInstance(address _hub) external returns (address) {
        address policyManager = address(new PolicyManager(_hub));
        childExists[policyManager] = true;
        emit NewInstance(_hub, policyManager);
        return policyManager;
    }
}

interface IPolicyManagerFactory {
    function createInstance(address _hub) external returns (address);
}

interface IPolicy {
    enum Applied { pre, post }

    // In Trading context:
    // addresses: Order maker, Order taker, Order maker asset, Order taker asset, Exchange address
    // values: Maker token quantity, Taker token quantity, Fill Taker Quantity

    // In Participation context:
    // address[0]: Investor address, address[3]: Investment asset
    function rule(bytes4 sig, address[5] calldata addresses, uint[3] calldata values, bytes32 identifier) external returns (bool);

    function position() external view returns (Applied);
    function identifier() external view returns (string memory);
}

contract UserWhitelist is DSAuth {
    enum Applied { pre, post }

    event ListAddition(address indexed who);
    event ListRemoval(address indexed who);

    mapping (address => bool) public whitelisted;

    constructor(address[] memory _preApproved) public {
        batchAddToWhitelist(_preApproved);
    }

    function addToWhitelist(address _who) public auth {
        whitelisted[_who] = true;
        emit ListAddition(_who);
    }

    function removeFromWhitelist(address _who) public auth {
        whitelisted[_who] = false;
        emit ListRemoval(_who);
    }

    function batchAddToWhitelist(address[] memory _members) public auth {
        for (uint i = 0; i < _members.length; i++) {
            addToWhitelist(_members[i]);
        }
    }

    function batchRemoveFromWhitelist(address[] memory _members) public auth {
        for (uint i = 0; i < _members.length; i++) {
            removeFromWhitelist(_members[i]);
        }
    }

    function rule(bytes4 sig, address[5] calldata addresses, uint[3] calldata values, bytes32 identifier) external returns (bool) {
        return whitelisted[addresses[0]];
    }

    function position() external pure returns (Applied) { return Applied.pre; }
    function identifier() external pure returns (string memory) { return 'UserWhitelist'; }
}

contract AddressList is DSAuth {

    event ListAddition(address[] ones);

    mapping(address => bool) internal list;
    address[] internal mirror;

    constructor(address[] memory _assets) public {
        for (uint i = 0; i < _assets.length; i++) {
            if (!isMember(_assets[i])) { // filter duplicates in _assets
                list[_assets[i]] = true;
                mirror.push(_assets[i]);
            }
        }
        emit ListAddition(_assets);
    }

    /// @return whether an asset is in the list
    function isMember(address _asset) public view returns (bool) {
        return list[_asset];
    }

    /// @return number of assets specified in the list
    function getMemberCount() external view returns (uint) {
        return mirror.length;
    }

    /// @return array of all listed asset addresses
    function getMembers() external view returns (address[] memory) { return mirror; }
}

contract Participation is TokenUser, AmguConsumer, Spoke {
    event EnableInvestment (address[] asset);
    event DisableInvestment (address[] assets);

    event InvestmentRequest (
        address indexed requestOwner,
        address indexed investmentAsset,
        uint requestedShares,
        uint investmentAmount
    );

    event RequestExecution (
        address indexed requestOwner,
        address indexed executor,
        address indexed investmentAsset,
        uint investmentAmount,
        uint requestedShares
    );

    event CancelRequest (
        address indexed requestOwner
    );

    event Redemption (
        address indexed redeemer,
        address[] assets,
        uint[] assetQuantities,
        uint redeemedShares
    );

    struct Request {
        address investmentAsset;
        uint investmentAmount;
        uint requestedShares;
        uint timestamp;
    }

    uint constant public SHARES_DECIMALS = 18;
    uint constant public REQUEST_LIFESPAN = 1 days;

    mapping (address => Request) public requests;
    mapping (address => bool) public investAllowed;
    mapping (address => bool) public hasInvested; // for information purposes only (read)

    address[] public historicalInvestors; // for information purposes only (read)

    constructor(address _hub, address[] memory _defaultAssets, address _registry)
        public
        Spoke(_hub)
    {
        routes.registry = _registry;
        _enableInvestment(_defaultAssets);
    }

    receive() external payable {}

    function _enableInvestment(address[] memory _assets) internal {
        for (uint i = 0; i < _assets.length; i++) {
            require(
                Registry(routes.registry).assetIsRegistered(_assets[i]),
                "Asset not registered"
            );
            investAllowed[_assets[i]] = true;
        }
        emit EnableInvestment(_assets);
    }

    function enableInvestment(address[] calldata _assets) external auth {
        _enableInvestment(_assets);
    }

    function disableInvestment(address[] calldata _assets) external auth {
        for (uint i = 0; i < _assets.length; i++) {
            investAllowed[_assets[i]] = false;
        }
        emit DisableInvestment(_assets);
    }

    function hasRequest(address _who) public view returns (bool) {
        return requests[_who].timestamp > 0;
    }

    function hasExpiredRequest(address _who) public view returns (bool) {
        return block.timestamp > add(requests[_who].timestamp, REQUEST_LIFESPAN);
    }

    /// @notice Whether request is OK and invest delay is being respected
    /// @dev Request valid if price update happened since request and not expired
    /// @dev If no shares exist and not expired, request can be executed immediately
    function hasValidRequest(address _who) public view returns (bool) {
        IPriceSource priceSource = IPriceSource(priceSource());
        bool delayRespectedOrNoShares = requests[_who].timestamp < priceSource.getLastUpdate() ||
            Shares(routes.shares).totalSupply() == 0;

        return hasRequest(_who) &&
            delayRespectedOrNoShares &&
            !hasExpiredRequest(_who) &&
            requests[_who].investmentAmount > 0 &&
            requests[_who].requestedShares > 0;
    }

    function requestInvestment(
        uint requestedShares,
        uint investmentAmount,
        address investmentAsset
    )
        external
        notShutDown
        payable
        amguPayable(true)
        onlyInitialized
    {
        PolicyManager(routes.policyManager).preValidate(
            msg.sig,
            [msg.sender, address(0), address(0), investmentAsset, address(0)],
            [uint(0), uint(0), uint(0)],
            bytes32(0)
        );
        require(
            investAllowed[investmentAsset],
            "Investment not allowed in this asset"
        );
        safeTransferFrom(
            investmentAsset, msg.sender, address(this), investmentAmount
        );
        require(
            requests[msg.sender].timestamp == 0,
            "Only one request can exist at a time"
        );
        requests[msg.sender] = Request({
            investmentAsset: investmentAsset,
            investmentAmount: investmentAmount,
            requestedShares: requestedShares,
            timestamp: block.timestamp
        });
        PolicyManager(routes.policyManager).postValidate(
            msg.sig,
            [msg.sender, address(0), address(0), investmentAsset, address(0)],
            [uint(0), uint(0), uint(0)],
            bytes32(0)
        );

        emit InvestmentRequest(
            msg.sender,
            investmentAsset,
            requestedShares,
            investmentAmount
        );
    }

    function _cancelRequestFor(address requestOwner) internal {
        require(hasRequest(requestOwner), "No request to cancel");
        IPriceSource priceSource = IPriceSource(priceSource());
        Request memory request = requests[requestOwner];
        require(
            !priceSource.hasValidPrice(request.investmentAsset) ||
            hasExpiredRequest(requestOwner) ||
            hub.isShutDown(),
            "No cancellation condition was met"
        );
        IERC20 investmentAsset = IERC20(request.investmentAsset);
        uint investmentAmount = request.investmentAmount;
        delete requests[requestOwner];
        msg.sender.transfer(Registry(routes.registry).incentive());
        safeTransfer(address(investmentAsset), requestOwner, investmentAmount);

        emit CancelRequest(requestOwner);
    }

    /// @notice Can only cancel when no price, request expired or fund shut down
    /// @dev Only request owner can cancel their request
    function cancelRequest() external payable amguPayable(false) {
        _cancelRequestFor(msg.sender);
    }

    function cancelRequestFor(address requestOwner)
        external
        payable
        amguPayable(false)
    {
        _cancelRequestFor(requestOwner);
    }

    function executeRequestFor(address requestOwner)
        external
        notShutDown
        amguPayable(false)
        payable
    {
        Request memory request = requests[requestOwner];
        require(
            hasValidRequest(requestOwner),
            "No valid request for this address"
        );

        FeeManager(routes.feeManager).rewardManagementFee();

        uint totalShareCostInInvestmentAsset = Accounting(routes.accounting)
            .getShareCostInAsset(
                request.requestedShares,
                request.investmentAsset
            );

        require(
            totalShareCostInInvestmentAsset <= request.investmentAmount,
            "Invested amount too low"
        );
        // send necessary amount of investmentAsset to vault
        safeTransfer(
            request.investmentAsset,
            routes.vault,
            totalShareCostInInvestmentAsset
        );

        uint investmentAssetChange = sub(
            request.investmentAmount,
            totalShareCostInInvestmentAsset
        );

        // return investmentAsset change to request owner
        if (investmentAssetChange > 0) {
            safeTransfer(
                request.investmentAsset,
                requestOwner,
                investmentAssetChange
            );
        }

        msg.sender.transfer(Registry(routes.registry).incentive());

        Shares(routes.shares).createFor(requestOwner, request.requestedShares);
        Accounting(routes.accounting).addAssetToOwnedAssets(request.investmentAsset);

        if (!hasInvested[requestOwner]) {
            hasInvested[requestOwner] = true;
            historicalInvestors.push(requestOwner);
        }

        emit RequestExecution(
            requestOwner,
            msg.sender,
            request.investmentAsset,
            request.investmentAmount,
            request.requestedShares
        );
        delete requests[requestOwner];
    }

    function getOwedPerformanceFees(uint shareQuantity)
        public
        returns (uint remainingShareQuantity)
    {
        Shares shares = Shares(routes.shares);

        uint totalPerformanceFee = FeeManager(routes.feeManager).performanceFeeAmount();
        // The denominator is augmented because performanceFeeAmount() accounts for inflation
        // Since shares are directly transferred, we don't need to account for inflation in this case
        uint performanceFeePortion = mul(
            totalPerformanceFee,
            shareQuantity
        ) / add(shares.totalSupply(), totalPerformanceFee);
        return performanceFeePortion;
    }

    /// @dev "Happy path" (no asset throws & quantity available)
    /// @notice Redeem all shares and across all assets
    function redeem() external {
        uint ownedShares = Shares(routes.shares).balanceOf(msg.sender);
        redeemQuantity(ownedShares);
    }

    /// @notice Redeem shareQuantity across all assets
    function redeemQuantity(uint shareQuantity) public {
        address[] memory assetList;
        assetList = Accounting(routes.accounting).getOwnedAssets();
        redeemWithConstraints(shareQuantity, assetList);
    }

    // TODO: reconsider the scenario where the user has enough funds to force shutdown on a large trade (any way around this?)
    /// @dev Redeem only selected assets (used only when an asset throws)
    function redeemWithConstraints(uint shareQuantity, address[] memory requestedAssets) public {
        Shares shares = Shares(routes.shares);
        require(
            shares.balanceOf(msg.sender) >= shareQuantity &&
            shares.balanceOf(msg.sender) > 0,
            "Sender does not have enough shares to fulfill request"
        );

        uint owedPerformanceFees = 0;
        if (
            IPriceSource(priceSource()).hasValidPrices(requestedAssets) &&
            msg.sender != hub.manager()
        ) {
            FeeManager(routes.feeManager).rewardManagementFee();
            owedPerformanceFees = getOwedPerformanceFees(shareQuantity);
            shares.destroyFor(msg.sender, owedPerformanceFees);
            shares.createFor(hub.manager(), owedPerformanceFees);
        }
        uint remainingShareQuantity = sub(shareQuantity, owedPerformanceFees);

        address ofAsset;
        uint[] memory ownershipQuantities = new uint[](requestedAssets.length);
        address[] memory redeemedAssets = new address[](requestedAssets.length);
        // Check whether enough assets held by fund
        Accounting accounting = Accounting(routes.accounting);
        for (uint i = 0; i < requestedAssets.length; ++i) {
            ofAsset = requestedAssets[i];
            require(
                accounting.isInAssetList(ofAsset),
                "Requested asset not in asset list"
            );
            for (uint j = 0; j < redeemedAssets.length; j++) {
                require(
                    ofAsset != redeemedAssets[j],
                    "Asset can only be redeemed once"
                );
            }
            redeemedAssets[i] = ofAsset;
            uint quantityHeld = accounting.assetHoldings(ofAsset);
            if (quantityHeld == 0) continue;

            // participant's ownership percentage of asset holdings
            ownershipQuantities[i] = mul(quantityHeld, remainingShareQuantity) / shares.totalSupply();
        }

        shares.destroyFor(msg.sender, remainingShareQuantity);

        // Transfer owned assets
        for (uint k = 0; k < requestedAssets.length; ++k) {
            ofAsset = requestedAssets[k];
            if (ownershipQuantities[k] == 0) {
                continue;
            } else {
                Vault(routes.vault).withdraw(ofAsset, ownershipQuantities[k]);
                safeTransfer(ofAsset, msg.sender, ownershipQuantities[k]);
            }
        }
        emit Redemption(
            msg.sender,
            requestedAssets,
            ownershipQuantities,
            remainingShareQuantity
        );
    }

    function getHistoricalInvestors() external view returns (address[] memory) {
        return historicalInvestors;
    }

    function engine() public view override(AmguConsumer, Spoke) returns (address) { return Spoke.engine(); }
    function mlnToken() public view override(AmguConsumer, Spoke) returns (address) { return Spoke.mlnToken(); }
    function priceSource() public view override(AmguConsumer, Spoke) returns (address) { return Spoke.priceSource(); }
    function registry() public view override(AmguConsumer, Spoke) returns (address) { return Spoke.registry(); }
}

contract ParticipationFactory is Factory {
    event NewInstance(
        address indexed hub,
        address indexed instance,
        address[] defaultAssets,
        address registry
    );

    function createInstance(address _hub, address[] calldata _defaultAssets, address _registry)
        external
        returns (address)
    {
        address participation = address(
            new Participation(_hub, _defaultAssets, _registry)
        );
        childExists[participation] = true;
        emit NewInstance(_hub, participation, _defaultAssets, _registry);
        return participation;
    }
}

interface IParticipation {
    function requestInvestment(
        uint requestedShares,
        uint investmentAmount,
        address investmentAsset
    ) external payable;
    function hasRequest(address) external view returns (bool);
    function cancelRequest() external payable;
    function executeRequestFor(address requestOwner) external payable;
    function redeem() external;
    function redeemWithConstraints(uint shareQuantity, address[] calldata requestedAssets) external;
}

interface IParticipationFactory {
    function createInstance(address _hub, address[] calldata _defaultAssets, address _registry) external returns (address);
}

contract Spoke is DSAuth {
    Hub public hub;
    Hub.Routes public routes;
    bool public initialized;

    modifier onlyInitialized() {
        require(initialized, "Component not yet initialized");
        _;
    }

    modifier notShutDown() {
        require(!hub.isShutDown(), "Hub is shut down");
        _;
    }

    constructor(address _hub) public {
        hub = Hub(_hub);
        setAuthority(hub);
        setOwner(address(hub)); // temporary, to allow initialization
    }

    function initialize(address[11] calldata _spokes) external auth {
        require(msg.sender == address(hub));
        require(!initialized, "Already initialized");
        routes = Hub.Routes(
            _spokes[0],
            _spokes[1],
            _spokes[2],
            _spokes[3],
            _spokes[4],
            _spokes[5],
            _spokes[6],
            _spokes[7],
            _spokes[8],
            _spokes[9],
            _spokes[10]
        );
        initialized = true;
        setOwner(address(0));
    }

    function engine() public view virtual returns (address) { return routes.engine; }
    function mlnToken() public view virtual returns (address) { return routes.mlnToken; }
    function priceSource() public view virtual returns (address) { return hub.priceSource(); }
    function version() public view virtual returns (address) { return routes.version; }
    function registry() public view virtual returns (address) { return routes.registry; }
}

contract Hub is DSGuard {

    event FundShutDown();

    struct Routes {
        address accounting;
        address feeManager;
        address participation;
        address policyManager;
        address shares;
        address trading;
        address vault;
        address registry;
        address version;
        address engine;
        address mlnToken;
    }

    Routes public routes;
    address public manager;
    address public creator;
    string public name;
    bool public isShutDown;
    bool public fundInitialized;
    uint public creationTime;
    mapping (address => bool) public isSpoke;

    constructor(address _manager, string memory _name) public {
        creator = msg.sender;
        manager = _manager;
        name = _name;
        creationTime = block.timestamp;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can do this");
        _;
    }

    function shutDownFund() external {
        require(msg.sender == routes.version);
        isShutDown = true;
        emit FundShutDown();
    }

    function initializeAndSetPermissions(address[11] calldata _spokes) external onlyCreator {
        require(!fundInitialized, "Fund is already initialized");
        for (uint i = 0; i < _spokes.length; i++) {
            isSpoke[_spokes[i]] = true;
        }
        routes.accounting = _spokes[0];
        routes.feeManager = _spokes[1];
        routes.participation = _spokes[2];
        routes.policyManager = _spokes[3];
        routes.shares = _spokes[4];
        routes.trading = _spokes[5];
        routes.vault = _spokes[6];
        routes.registry = _spokes[7];
        routes.version = _spokes[8];
        routes.engine = _spokes[9];
        routes.mlnToken = _spokes[10];

        Spoke(routes.accounting).initialize(_spokes);
        Spoke(routes.feeManager).initialize(_spokes);
        Spoke(routes.participation).initialize(_spokes);
        Spoke(routes.policyManager).initialize(_spokes);
        Spoke(routes.shares).initialize(_spokes);
        Spoke(routes.trading).initialize(_spokes);
        Spoke(routes.vault).initialize(_spokes);

        permit(routes.participation, routes.vault, bytes4(keccak256('withdraw(address,uint256)')));
        permit(routes.trading, routes.vault, bytes4(keccak256('withdraw(address,uint256)')));
        permit(routes.participation, routes.shares, bytes4(keccak256('createFor(address,uint256)')));
        permit(routes.participation, routes.shares, bytes4(keccak256('destroyFor(address,uint256)')));
        permit(routes.feeManager, routes.shares, bytes4(keccak256('createFor(address,uint256)')));
        permit(routes.participation, routes.accounting, bytes4(keccak256('addAssetToOwnedAssets(address)')));
        permit(routes.trading, routes.accounting, bytes4(keccak256('addAssetToOwnedAssets(address)')));
        permit(routes.trading, routes.accounting, bytes4(keccak256('removeFromOwnedAssets(address)')));
        permit(routes.accounting, routes.feeManager, bytes4(keccak256('rewardAllFees()')));
        permit(manager, routes.policyManager, bytes4(keccak256('register(bytes4,address)')));
        permit(manager, routes.policyManager, bytes4(keccak256('batchRegister(bytes4[],address[])')));
        permit(manager, routes.participation, bytes4(keccak256('enableInvestment(address[])')));
        permit(manager, routes.participation, bytes4(keccak256('disableInvestment(address[])')));
        permit(manager, routes.trading, bytes4(keccak256('addExchange(address,address)')));
        fundInitialized = true;
    }

    function vault() external view returns (address) { return routes.vault; }
    function accounting() external view returns (address) { return routes.accounting; }
    function priceSource() external view returns (address) { return Registry(routes.registry).priceSource(); }
    function participation() external view returns (address) { return routes.participation; }
    function trading() external view returns (address) { return routes.trading; }
    function shares() external view returns (address) { return routes.shares; }
    function registry() external view returns (address) { return routes.registry; }
    function version() external view returns (address) { return routes.version; }
    function policyManager() external view returns (address) { return routes.policyManager; }
}

contract PerformanceFee is DSMath {

    event HighWaterMarkUpdate(address indexed feeManager, uint indexed hwm);

    uint public constant DIVISOR = 10 ** 18;
    uint public constant REDEEM_WINDOW = 1 weeks;

    mapping(address => uint) public highWaterMark;
    mapping(address => uint) public lastPayoutTime;
    mapping(address => uint) public initializeTime;
    mapping(address => uint) public performanceFeeRate;
    mapping(address => uint) public performanceFeePeriod;

    /// @notice Sets initial state of the fee for a user
    function initializeForUser(uint feeRate, uint feePeriod, address denominationAsset) external {
        require(lastPayoutTime[msg.sender] == 0, "Already initialized");
        performanceFeeRate[msg.sender] = feeRate;
        performanceFeePeriod[msg.sender] = feePeriod;
        highWaterMark[msg.sender] = 10 ** uint(ERC20WithFields(denominationAsset).decimals());
        lastPayoutTime[msg.sender] = block.timestamp;
        initializeTime[msg.sender] = block.timestamp;
    }

    /// @notice Assumes management fee is zero
    function feeAmount() external returns (uint feeInShares) {
        Hub hub = FeeManager(msg.sender).hub();
        Accounting accounting = Accounting(hub.accounting());
        Shares shares = Shares(hub.shares());
        uint gav = accounting.calcGav();
        uint gavPerShare = shares.totalSupply() > 0 ?
            accounting.valuePerShare(gav, shares.totalSupply())
            : accounting.DEFAULT_SHARE_PRICE();
        if (
            gavPerShare > highWaterMark[msg.sender] &&
            shares.totalSupply() != 0 &&
            gav != 0
        ) {
            uint sharePriceGain = sub(gavPerShare, highWaterMark[msg.sender]);
            uint totalGain = mul(sharePriceGain, shares.totalSupply()) / DIVISOR;
            uint feeInAsset = mul(totalGain, performanceFeeRate[msg.sender]) / DIVISOR;
            uint preDilutionFee = mul(shares.totalSupply(), feeInAsset) / gav;
            feeInShares =
                mul(preDilutionFee, shares.totalSupply()) /
                sub(shares.totalSupply(), preDilutionFee);
        }
        else {
            feeInShares = 0;
        }
        return feeInShares;
    }

    function canUpdate(address _who) public view returns (bool) {
        uint timeSinceInit = sub(
            block.timestamp,
            initializeTime[_who]
        );
        uint secondsSinceLastPeriod = timeSinceInit % performanceFeePeriod[_who];
        uint lastPeriodEnd = sub(block.timestamp, secondsSinceLastPeriod);
        return (
            secondsSinceLastPeriod <= REDEEM_WINDOW &&
            lastPayoutTime[_who] < lastPeriodEnd
        );
    }

    /// @notice Assumes management fee is zero
    function updateState() external {
        require(lastPayoutTime[msg.sender] != 0, "Not initialized");
        require(
            canUpdate(msg.sender),
            "Not within a update window or already updated this period"
        );
        Hub hub = FeeManager(msg.sender).hub();
        Accounting accounting = Accounting(hub.accounting());
        Shares shares = Shares(hub.shares());
        uint gav = accounting.calcGav();
        uint currentGavPerShare = accounting.valuePerShare(gav, shares.totalSupply());
        require(
            currentGavPerShare > highWaterMark[msg.sender],
            "Current share price does not pass high water mark"
        );
        lastPayoutTime[msg.sender] = block.timestamp;
        highWaterMark[msg.sender] = currentGavPerShare;
        emit HighWaterMarkUpdate(msg.sender, currentGavPerShare);
    }

    function identifier() external pure returns (uint) {
        return 1;
    }
}

contract ManagementFee is DSMath {

    uint public DIVISOR = 10 ** 18;

    mapping (address => uint) public managementFeeRate;
    mapping (address => uint) public lastPayoutTime;

    function feeAmount() external view returns (uint feeInShares) {
        Hub hub = FeeManager(msg.sender).hub();
        Shares shares = Shares(hub.shares());
        if (shares.totalSupply() == 0 || managementFeeRate[msg.sender] == 0) {
            feeInShares = 0;
        } else {
            uint timePassed = sub(block.timestamp, lastPayoutTime[msg.sender]);
            uint preDilutionFeeShares = mul(mul(shares.totalSupply(), managementFeeRate[msg.sender]) / DIVISOR, timePassed) / 365 days;
            feeInShares =
                mul(preDilutionFeeShares, shares.totalSupply()) /
                sub(shares.totalSupply(), preDilutionFeeShares);
        }
        return feeInShares;
    }

    function initializeForUser(uint feeRate, uint feePeriod, address denominationAsset) external {
        require(lastPayoutTime[msg.sender] == 0);
        managementFeeRate[msg.sender] = feeRate;
        lastPayoutTime[msg.sender] = block.timestamp;
    }

    function updateState() external {
        lastPayoutTime[msg.sender] = block.timestamp;
    }

    function identifier() external pure returns (uint) {
        return 0;
    }
}

interface IFeeManagerFactory {
    function createInstance(
        address _hub,
        address _denominationAsset,
        address[] calldata _fees,
        uint[] calldata _feeRates,
        uint[] calldata _feePeriods,
        address _registry
    ) external returns (address);
}

interface IFee {
    function initializeForUser(uint feeRate, uint feePeriod, address denominationAsset) external;
    function feeAmount() external returns (uint);
    function updateState() external;

    /// @notice Used to enforce a convention
    function identifier() external view returns (uint);
}

contract FeeManager is DSMath, Spoke {

    event FeeReward(uint shareQuantity);
    event FeeRegistration(address fee);

    struct FeeInfo {
        address feeAddress;
        uint feeRate;
        uint feePeriod;
    }

    IFee[] public fees;
    mapping (address => bool) public feeIsRegistered;

    constructor(address _hub, address _denominationAsset, address[] memory _fees, uint[] memory _rates, uint[] memory _periods, address _registry) Spoke(_hub) public {
        for (uint i = 0; i < _fees.length; i++) {
            require(
                Registry(_registry).isFeeRegistered(_fees[i]),
                "Fee must be known to Registry"
            );
            register(_fees[i], _rates[i], _periods[i], _denominationAsset);
        }
        if (fees.length > 0) {
            require(
                fees[0].identifier() == 0,
                "Management fee must be at 0 index"
            );
        }
        if (fees.length > 1) {
            require(
                fees[1].identifier() == 1,
                "Performance fee must be at 1 index"
            );
        }
    }

    function register(address feeAddress, uint feeRate, uint feePeriod, address denominationAsset) internal {
        require(!feeIsRegistered[feeAddress], "Fee already registered");
        feeIsRegistered[feeAddress] = true;
        fees.push(IFee(feeAddress));
        IFee(feeAddress).initializeForUser(feeRate, feePeriod, denominationAsset);  // initialize state
        emit FeeRegistration(feeAddress);
    }

    function totalFeeAmount() external returns (uint total) {
        for (uint i = 0; i < fees.length; i++) {
            total = add(total, fees[i].feeAmount());
        }
        return total;
    }

    /// @dev Shares to be inflated after update state
    function _rewardFee(IFee fee) internal {
        require(feeIsRegistered[address(fee)], "Fee is not registered");
        uint rewardShares = fee.feeAmount();
        fee.updateState();
        Shares(routes.shares).createFor(hub.manager(), rewardShares);
        emit FeeReward(rewardShares);
    }

    function _rewardAllFees() internal {
        for (uint i = 0; i < fees.length; i++) {
            _rewardFee(fees[i]);
        }
    }

    /// @dev Used when calling from other components
    function rewardAllFees() public auth { _rewardAllFees(); }

    /// @dev Convenience function; anyone can reward management fee any time
    /// @dev Convention that management fee is 0
    function rewardManagementFee() public {
        if (fees.length >= 1) _rewardFee(fees[0]);
    }

    /// @dev Convenience function
    /// @dev Convention that management fee is 0
    function managementFeeAmount() external returns (uint) {
        if (fees.length < 1) return 0;
        return fees[0].feeAmount();
    }

    /// @dev Convenience function
    /// @dev Convention that performace fee is 1
    function performanceFeeAmount() external returns (uint) {
        if (fees.length < 2) return 0;
        return fees[1].feeAmount();
    }
}

contract FeeManagerFactory is Factory {
    function createInstance(
        address _hub,
        address _denominationAsset,
        address[] memory _fees,
        uint[] memory _feeRates,
        uint[] memory _feePeriods,
        address _registry
    ) public returns (address) {
        address feeManager = address(
            new FeeManager(_hub, _denominationAsset, _fees, _feeRates, _feePeriods, _registry)
        );
        childExists[feeManager] = true;
        emit NewInstance(_hub, feeManager);
        return feeManager;
    }
}

interface IAccounting {
    function getOwnedAssetsLength() external view returns (uint);
    function getFundHoldings() external returns (uint[] memory, address[] memory);
    function calcAssetGAV(address ofAsset) external returns (uint);
    function calcGav() external returns (uint gav);
    function calcNav(uint gav, uint unclaimedFees) external pure returns (uint);
    function valuePerShare(uint totalValue, uint numShares) external view returns (uint);
    function performCalculations() external returns (
        uint gav,
        uint unclaimedFees,
        uint feesInShares,
        uint nav,
        uint sharePrice,
        uint gavPerShareNetManagementFee
    );
    function calcGavPerShareNetManagementFee() external returns (uint);
}

interface IAccountingFactory {
    function createInstance(address _hub, address _denominationAsset, address _nativeAsset) external returns (address);
}


contract Accounting is AmguConsumer, Spoke {

    event AssetAddition(address indexed asset);
    event AssetRemoval(address indexed asset);

    struct Calculations {
        uint gav;
        uint nav;
        uint allocatedFees;
        uint totalSupply;
        uint timestamp;
    }

    uint constant public MAX_OWNED_ASSETS = 20;
    address[] public ownedAssets;
    mapping (address => bool) public isInAssetList;
    uint public constant SHARES_DECIMALS = 18;
    address public NATIVE_ASSET;
    address public DENOMINATION_ASSET;
    uint public DENOMINATION_ASSET_DECIMALS;
    uint public DEFAULT_SHARE_PRICE;
    Calculations public atLastAllocation;

    constructor(address _hub, address _denominationAsset, address _nativeAsset)
        public
        Spoke(_hub)
    {
        DENOMINATION_ASSET = _denominationAsset;
        NATIVE_ASSET = _nativeAsset;
        DENOMINATION_ASSET_DECIMALS = ERC20WithFields(DENOMINATION_ASSET).decimals();
        DEFAULT_SHARE_PRICE = 10 ** uint(DENOMINATION_ASSET_DECIMALS);
    }

    function getOwnedAssetsLength() external view returns (uint256) {
        return ownedAssets.length;
    }

    function getOwnedAssets() external view returns (address[] memory) {
        return ownedAssets;
    }

    function assetHoldings(address _asset) public returns (uint256) {
        return add(
            uint256(ERC20WithFields(_asset).balanceOf(routes.vault)),
            ITrading(routes.trading).updateAndGetQuantityBeingTraded(_asset)
        );
    }

    /// @dev Returns sparse array
    function getFundHoldings() external returns (uint[] memory, address[] memory) {
        uint[] memory _quantities = new uint[](ownedAssets.length);
        address[] memory _assets = new address[](ownedAssets.length);
        for (uint i = 0; i < ownedAssets.length; i++) {
            address ofAsset = ownedAssets[i];
            // assetHoldings formatting: mul(exchangeHoldings, 10 ** assetDecimal)
            uint quantityHeld = assetHoldings(ofAsset);
            _assets[i] = ofAsset;
            _quantities[i] = quantityHeld;
        }
        return (_quantities, _assets);
    }

    function calcAssetGAV(address _queryAsset) external returns (uint) {
        uint queryAssetQuantityHeld = assetHoldings(_queryAsset);
        return IPriceSource(priceSource()).convertQuantity(
            queryAssetQuantityHeld, _queryAsset, DENOMINATION_ASSET
        );
    }

    // prices are quoted in DENOMINATION_ASSET so they use denominationDecimals
    function calcGav() public returns (uint gav) {
        for (uint i = 0; i < ownedAssets.length; ++i) {
            address asset = ownedAssets[i];
            // assetHoldings formatting: mul(exchangeHoldings, 10 ** assetDecimals)
            uint quantityHeld = assetHoldings(asset);
            // Dont bother with the calculations if the balance of the asset is 0
            if (quantityHeld == 0) {
                continue;
            }
            // gav as sum of mul(assetHoldings, assetPrice) with formatting: mul(mul(exchangeHoldings, exchangePrice), 10 ** shareDecimals)
            gav = add(
                gav,
                IPriceSource(priceSource()).convertQuantity(
                    quantityHeld, asset, DENOMINATION_ASSET
                )
            );
        }
        return gav;
    }

    function calcNav(uint gav, uint unclaimedFeesInDenominationAsset) public pure returns (uint) {
        return sub(gav, unclaimedFeesInDenominationAsset);
    }

    function valuePerShare(uint totalValue, uint numShares) public pure returns (uint) {
        require(numShares > 0, "No shares to calculate value for");
        return (totalValue * 10 ** uint(SHARES_DECIMALS)) / numShares;
    }

    function performCalculations()
        public
        returns (
            uint gav,
            uint feesInDenominationAsset,  // unclaimed amount
            uint feesInShares,             // unclaimed amount
            uint nav,
            uint sharePrice,
            uint gavPerShareNetManagementFee
        )
    {
        gav = calcGav();
        uint totalSupply = Shares(routes.shares).totalSupply();
        feesInShares = FeeManager(routes.feeManager).totalFeeAmount();
        feesInDenominationAsset = (totalSupply == 0) ?
            0 :
            mul(feesInShares, gav) / add(totalSupply, feesInShares);
        nav = calcNav(gav, feesInDenominationAsset);

        // The total share supply including the value of feesInDenominationAsset, measured in shares of this fund
        uint totalSupplyAccountingForFees = add(totalSupply, feesInShares);
        sharePrice = (totalSupply > 0) ?
            valuePerShare(gav, totalSupplyAccountingForFees) :
            DEFAULT_SHARE_PRICE;
        gavPerShareNetManagementFee = (totalSupply > 0) ?
            valuePerShare(gav, add(totalSupply, FeeManager(routes.feeManager).managementFeeAmount())) :
            DEFAULT_SHARE_PRICE;
        return (gav, feesInDenominationAsset, feesInShares, nav, sharePrice, gavPerShareNetManagementFee);
    }

    function calcGavPerShareNetManagementFee()
        public
        returns (uint gavPerShareNetManagementFee)
    {
        (,,,,,gavPerShareNetManagementFee) = performCalculations();
        return gavPerShareNetManagementFee;
    }

    function getShareCostInAsset(uint _numShares, address _altAsset)
        external
        returns (uint)
    {
        uint denominationAssetQuantity = mul(
            _numShares,
            calcGavPerShareNetManagementFee()
        ) / 10 ** uint(SHARES_DECIMALS);
        return IPriceSource(priceSource()).convertQuantity(
            denominationAssetQuantity, DENOMINATION_ASSET, _altAsset
        );
    }

    /// @notice Reward all fees and perform some updates
    /// @dev Anyone can call this
    function triggerRewardAllFees()
        external
        amguPayable(false)
        payable
    {
        updateOwnedAssets();
        uint256 gav;
        uint256 feesInDenomination;
        uint256 feesInShares;
        uint256 nav;
        (gav, feesInDenomination, feesInShares, nav,,) = performCalculations();
        uint256 totalSupply = Shares(routes.shares).totalSupply();
        FeeManager(routes.feeManager).rewardAllFees();
        atLastAllocation = Calculations({
            gav: gav,
            nav: nav,
            allocatedFees: feesInDenomination,
            totalSupply: totalSupply,
            timestamp: block.timestamp
        });
    }

    /// @dev Check holdings for all assets, and adjust list
    function updateOwnedAssets() public {
        for (uint i = 0; i < ownedAssets.length; i++) {
            address asset = ownedAssets[i];
            if (
                assetHoldings(asset) == 0 &&
                !(asset == address(DENOMINATION_ASSET)) &&
                ITrading(routes.trading).getOpenMakeOrdersAgainstAsset(asset) == 0
            ) {
                _removeFromOwnedAssets(asset);
            }
        }
    }

    function addAssetToOwnedAssets(address _asset) external auth {
        _addAssetToOwnedAssets(_asset);
    }

    function removeFromOwnedAssets(address _asset) external auth {
        _removeFromOwnedAssets(_asset);
    }

    /// @dev Just pass if asset already in list
    function _addAssetToOwnedAssets(address _asset) internal {
        if (isInAssetList[_asset]) { return; }

        require(
            ownedAssets.length < MAX_OWNED_ASSETS,
            "Max owned asset limit reached"
        );
        isInAssetList[_asset] = true;
        ownedAssets.push(_asset);
        emit AssetAddition(_asset);
    }

    /// @dev Just pass if asset not in list
    function _removeFromOwnedAssets(address _asset) internal {
        if (!isInAssetList[_asset]) { return; }

        isInAssetList[_asset] = false;
        for (uint i; i < ownedAssets.length; i++) {
            if (ownedAssets[i] == _asset) {
                ownedAssets[i] = ownedAssets[ownedAssets.length - 1];
                ownedAssets.pop();
                break;
            }
        }
        emit AssetRemoval(_asset);
    }

    function engine() public view override(AmguConsumer, Spoke) returns (address) { return Spoke.engine(); }
    function mlnToken() public view override(AmguConsumer, Spoke) returns (address) { return Spoke.mlnToken(); }
    function priceSource() public view override(AmguConsumer, Spoke) returns (address) { return Spoke.priceSource(); }
    function registry() public view override(AmguConsumer, Spoke) returns (address) { return Spoke.registry(); }
}

contract AccountingFactory is Factory {
    event NewInstance(
        address indexed hub,
        address indexed instance,
        address denominationAsset,
        address nativeAsset
    );

    function createInstance(address _hub, address _denominationAsset, address _nativeAsset) external returns (address) {
        address accounting = address(new Accounting(_hub, _denominationAsset, _nativeAsset));
        childExists[accounting] = true;
        emit NewInstance(_hub, accounting, _denominationAsset, _nativeAsset);
        return accounting;
    }
}

contract FundFactory is AmguConsumer, Factory {

    event NewFund(
        address indexed manager,
        address indexed hub,
        address[11] routes
    );

    IVersion public version;
    Registry public associatedRegistry;
    IAccountingFactory public accountingFactory;
    IFeeManagerFactory public feeManagerFactory;
    IParticipationFactory public participationFactory;
    IPolicyManagerFactory public policyManagerFactory;
    ISharesFactory public sharesFactory;
    ITradingFactory public tradingFactory;
    IVaultFactory public vaultFactory;

    address[] public funds;
    mapping (address => address) public managersToHubs;
    mapping (address => Hub.Routes) public managersToRoutes;
    mapping (address => Settings) public managersToSettings;

    /// @dev Parameters stored when beginning setup
    struct Settings {
        string name;
        address[] exchanges;
        address[] adapters;
        address denominationAsset;
        address[] defaultInvestmentAssets;
        address[] fees;
        uint[] feeRates;
        uint[] feePeriods;
    }

    constructor(
        address _accountingFactory,
        address _feeManagerFactory,
        address _participationFactory,
        address _sharesFactory,
        address _tradingFactory,
        address _vaultFactory,
        address _policyManagerFactory,
        address _version
    )
        public
    {
        accountingFactory = IAccountingFactory(_accountingFactory);
        feeManagerFactory = IFeeManagerFactory(_feeManagerFactory);
        participationFactory = IParticipationFactory(_participationFactory);
        sharesFactory = ISharesFactory(_sharesFactory);
        tradingFactory = ITradingFactory(_tradingFactory);
        vaultFactory = IVaultFactory(_vaultFactory);
        policyManagerFactory = IPolicyManagerFactory(_policyManagerFactory);
        version = IVersion(_version);
    }

    function componentExists(address _component) internal pure returns (bool) {
        return _component != address(0);
    }

    function ensureComponentNotSet(address _component) internal {
        require(
            !componentExists(_component),
            "This step has already been run"
        );
    }

    function ensureComponentSet(address _component) internal {
        require(
            componentExists(_component),
            "Component preprequisites not met"
        );
    }

    function beginSetup(
        string memory _name,
        address[] memory _fees,
        uint[] memory _feeRates,
        uint[] memory _feePeriods,
        address[] memory _exchanges,
        address[] memory _adapters,
        address _denominationAsset,
        address[] memory _defaultInvestmentAssets
    )
        public
    {
        ensureComponentNotSet(managersToHubs[msg.sender]);
        associatedRegistry.reserveFundName(
            msg.sender,
            _name
        );
        require(
            associatedRegistry.assetIsRegistered(_denominationAsset),
            "Denomination asset must be registered"
        );

        managersToHubs[msg.sender] = address(new Hub(msg.sender, _name));
        managersToSettings[msg.sender] = Settings(
            _name,
            _exchanges,
            _adapters,
            _denominationAsset,
            _defaultInvestmentAssets,
            _fees,
            _feeRates,
            _feePeriods
        );
        managersToRoutes[msg.sender].registry = address(associatedRegistry);
        managersToRoutes[msg.sender].version = address(version);
        managersToRoutes[msg.sender].engine = engine();
        managersToRoutes[msg.sender].mlnToken = mlnToken();
    }

    function _createAccountingFor(address _manager)
        internal
    {
        ensureComponentSet(managersToHubs[_manager]);
        ensureComponentNotSet(managersToRoutes[_manager].accounting);
        managersToRoutes[_manager].accounting = accountingFactory.createInstance(
            managersToHubs[_manager],
            managersToSettings[_manager].denominationAsset,
            associatedRegistry.nativeAsset()
        );
    }

    function createAccountingFor(address _manager) external amguPayable(false) payable { _createAccountingFor(_manager); }
    function createAccounting() external amguPayable(false) payable { _createAccountingFor(msg.sender); }

    function _createFeeManagerFor(address _manager)
        internal
    {
        ensureComponentSet(managersToHubs[_manager]);
        ensureComponentNotSet(managersToRoutes[_manager].feeManager);
        managersToRoutes[_manager].feeManager = feeManagerFactory.createInstance(
            managersToHubs[_manager],
            managersToSettings[_manager].denominationAsset,
            managersToSettings[_manager].fees,
            managersToSettings[_manager].feeRates,
            managersToSettings[_manager].feePeriods,
            managersToRoutes[_manager].registry
        );
    }

    function createFeeManagerFor(address _manager) external amguPayable(false) payable { _createFeeManagerFor(_manager); }
    function createFeeManager() external amguPayable(false) payable { _createFeeManagerFor(msg.sender); }

    function _createParticipationFor(address _manager)
        internal
    {
        ensureComponentSet(managersToHubs[_manager]);
        ensureComponentNotSet(managersToRoutes[_manager].participation);
        managersToRoutes[_manager].participation = participationFactory.createInstance(
            managersToHubs[_manager],
            managersToSettings[_manager].defaultInvestmentAssets,
            managersToRoutes[_manager].registry
        );
    }

    function createParticipationFor(address _manager) external amguPayable(false) payable { _createParticipationFor(_manager); }
    function createParticipation() external amguPayable(false) payable { _createParticipationFor(msg.sender); }

    function _createPolicyManagerFor(address _manager)
        internal
    {
        ensureComponentSet(managersToHubs[_manager]);
        ensureComponentNotSet(managersToRoutes[_manager].policyManager);
        managersToRoutes[_manager].policyManager = policyManagerFactory.createInstance(
            managersToHubs[_manager]
        );
    }

    function createPolicyManagerFor(address _manager) external amguPayable(false) payable { _createPolicyManagerFor(_manager); }
    function createPolicyManager() external amguPayable(false) payable { _createPolicyManagerFor(msg.sender); }

    function _createSharesFor(address _manager)
        internal
    {
        ensureComponentSet(managersToHubs[_manager]);
        ensureComponentNotSet(managersToRoutes[_manager].shares);
        managersToRoutes[_manager].shares = sharesFactory.createInstance(
            managersToHubs[_manager]
        );
    }

    function createSharesFor(address _manager) external amguPayable(false) payable { _createSharesFor(_manager); }
    function createShares() external amguPayable(false) payable { _createSharesFor(msg.sender); }

    function _createTradingFor(address _manager)
        internal
    {
        ensureComponentSet(managersToHubs[_manager]);
        ensureComponentNotSet(managersToRoutes[_manager].trading);
        managersToRoutes[_manager].trading = tradingFactory.createInstance(
            managersToHubs[_manager],
            managersToSettings[_manager].exchanges,
            managersToSettings[_manager].adapters,
            managersToRoutes[_manager].registry
        );
    }

    function createTradingFor(address _manager) external amguPayable(false) payable { _createTradingFor(_manager); }
    function createTrading() external amguPayable(false) payable { _createTradingFor(msg.sender); }

    function _createVaultFor(address _manager)
        internal
    {
        ensureComponentSet(managersToHubs[_manager]);
        ensureComponentNotSet(managersToRoutes[_manager].vault);
        managersToRoutes[_manager].vault = vaultFactory.createInstance(
            managersToHubs[_manager]
        );
    }

    function createVaultFor(address _manager) external amguPayable(false) payable { _createVaultFor(_manager); }
    function createVault() external amguPayable(false) payable { _createVaultFor(msg.sender); }

    function _completeSetupFor(address _manager) internal {
        Hub.Routes memory routes = managersToRoutes[_manager];
        Hub hub = Hub(managersToHubs[_manager]);
        require(!childExists[address(hub)], "Setup already complete");
        require(
            componentExists(address(hub)) &&
            componentExists(routes.accounting) &&
            componentExists(routes.feeManager) &&
            componentExists(routes.participation) &&
            componentExists(routes.policyManager) &&
            componentExists(routes.shares) &&
            componentExists(routes.trading) &&
            componentExists(routes.vault),
            "Components must be set before completing setup"
        );
        childExists[address(hub)] = true;
        hub.initializeAndSetPermissions([
            routes.accounting,
            routes.feeManager,
            routes.participation,
            routes.policyManager,
            routes.shares,
            routes.trading,
            routes.vault,
            routes.registry,
            routes.version,
            routes.engine,
            routes.mlnToken
        ]);
        funds.push(address(hub));
        associatedRegistry.registerFund(
            address(hub),
            _manager,
            managersToSettings[_manager].name
        );

        emit NewFund(
            msg.sender,
            address(hub),
            [
                routes.accounting,
                routes.feeManager,
                routes.participation,
                routes.policyManager,
                routes.shares,
                routes.trading,
                routes.vault,
                routes.registry,
                routes.version,
                routes.engine,
                routes.mlnToken
            ]
        );
    }

    function completeSetupFor(address _manager) external amguPayable(false) payable { _completeSetupFor(_manager); }
    function completeSetup() external amguPayable(false) payable { _completeSetupFor(msg.sender); }

    function getFundById(uint withId) external view returns (address) { return funds[withId]; }
    function getLastFundId() external view returns (uint) { return funds.length - 1; }

    function mlnToken() public view override returns (address) {
        return address(associatedRegistry.mlnToken());
    }
    function engine() public view override returns (address) {
        return address(associatedRegistry.engine());
    }
    function priceSource() public view override returns (address) {
        return address(associatedRegistry.priceSource());
    }
    function registry() public view override returns (address) { return address(associatedRegistry); }
    function getExchangesInfo(address user) public view returns (address[] memory) {
        return (managersToSettings[user].exchanges);
    }
}

contract Factory {
    mapping (address => bool) public childExists;

    event NewInstance(
        address indexed hub,
        address indexed instance
    );

    function isInstance(address _child) public view returns (bool) {
        return childExists[_child];
    }
}

contract ZeroExV3Adapter is DSMath, ExchangeAdapter {

    /// @param _orderAddresses [2] Order maker asset
    /// @param _orderAddresses [3] Order taker asset
    /// @param _orderAddresses [6] Order maker fee asset
    /// @param _orderAddresses [7] Order taker fee asset
    /// @param _orderValues [2] Order maker fee amount
    /// @param _orderValues [3] Order taker fee amount
    modifier orderAddressesMatchOrderData(
        address[8] memory _orderAddresses,
        uint[8] memory _orderValues,
        bytes[4] memory _orderData
    )
    {
        require(
            getAssetAddress(_orderData[0]) == _orderAddresses[2],
            "Maker asset data does not match order address in array"
        );
        require(
            getAssetAddress(_orderData[1]) == _orderAddresses[3],
            "Taker asset data does not match order address in array"
        );
        if (_orderValues[2] > 0) {
            require(
                getAssetAddress(_orderData[2]) == _orderAddresses[6],
                "Maker fee asset data does not match order address in array"
            );
        }
        if (_orderValues[3] > 0) {
            require(
                getAssetAddress(_orderData[3]) == _orderAddresses[7],
                "Taker fee asset data does not match order address in array"
            );
        }
        _;
    }

    //  METHODS

    //  PUBLIC METHODS

    /// @notice Make order by pre-approving signatures
    /// @param _targetExchange Address of the exchange
    /// @param _orderAddresses [2] Maker asset (Dest token)
    /// @param _orderAddresses [3] Taker asset (Src token)
    /// @param _orderData [0] Encoded data specific to maker asset
    /// @param _orderData [1] Encoded data specific to taker asset
    /// @param _signature _signature of the order.
    function makeOrder(
        address _targetExchange,
        address[8] memory _orderAddresses,
        uint[8] memory _orderValues,
        bytes[4] memory _orderData,
        bytes32 _identifier,
        bytes memory _signature
    )
        public
        override
        onlyManager
        notShutDown
        orderAddressesMatchOrderData(_orderAddresses, _orderValues, _orderData)
    {
        ensureCanMakeOrder(_orderAddresses[2]);

        IZeroExV3.Order memory order = constructOrderStruct(_orderAddresses, _orderValues, _orderData);
        address makerAsset = getAssetAddress(_orderData[0]);
        address takerAsset = getAssetAddress(_orderData[1]);

        // Order parameter checks
        getTrading().updateAndGetQuantityBeingTraded(makerAsset);
        ensureNotInOpenMakeOrder(makerAsset);

        approveAssetsMakeOrder(_targetExchange, order);

        IZeroExV3.OrderInfo memory orderInfo = IZeroExV3(_targetExchange).getOrderInfo(order);
        IZeroExV3(_targetExchange).preSign(orderInfo.orderHash);

        require(
            IZeroExV3(_targetExchange).isValidOrderSignature(order, _signature),
            "INVALID_ORDER_SIGNATURE"
        );

        updateStateMakeOrder(_targetExchange, order);
    }

    /// @notice Takes an active order on the selected exchange
    /// @dev These orders are expected to settle immediately
    /// @param _targetExchange Address of the exchange
    /// @param _orderAddresses [2] Order maker asset
    /// @param _orderAddresses [3] Order taker asset
    /// @param _orderValues [6] Fill amount: amount of taker token to be traded
    /// @param _signature _signature of the order.
    function takeOrder(
        address _targetExchange,
        address[8] memory _orderAddresses,
        uint[8] memory _orderValues,
        bytes[4] memory _orderData,
        bytes32 _identifier,
        bytes memory _signature
    )
        public
        override
        onlyManager
        notShutDown
        orderAddressesMatchOrderData(_orderAddresses, _orderValues, _orderData)
    {
        IZeroExV3.Order memory order = constructOrderStruct(_orderAddresses, _orderValues, _orderData);
        require(IZeroExV3(_targetExchange).isValidOrderSignature(order, _signature), "Order _signature is invalid");

        uint256 fillTakerQuantity = _orderValues[6];

        approveAssetsTakeOrder(_targetExchange, order);

        uint256 takerAssetFilledAmount = executeFill(_targetExchange, order, fillTakerQuantity, _signature);
        require(
            takerAssetFilledAmount == fillTakerQuantity,
            "Filled amount does not match desired fill amount"
        );

        updateStateTakeOrder(_targetExchange, order, fillTakerQuantity);
    }

    /// @notice Cancel the 0x make order
    /// @param _targetExchange Address of the exchange
    /// @param _orderAddresses [2] Order maker asset
    /// @param _identifier Order _identifier
    function cancelOrder(
        address _targetExchange,
        address[8] memory _orderAddresses,
        uint[8] memory _orderValues,
        bytes[4] memory _orderData,
        bytes32 _identifier,
        bytes memory _signature
    )
        public
        override
        orderAddressesMatchOrderData(_orderAddresses, _orderValues, _orderData)
    {
        IZeroExV3.Order memory order = getTrading().getZeroExV3OrderDetails(_identifier);
        ensureCancelPermitted(_targetExchange, getAssetAddress(order.makerAssetData), _identifier);
        if (order.expirationTimeSeconds > block.timestamp) {
            IZeroExV3(_targetExchange).cancelOrder(order);
        }

        revokeApproveAssetsCancelOrder(_targetExchange, order);

        updateStateCancelOrder(_targetExchange, order);
    }

    /// @dev Get order details
    function getOrder(address _targetExchange, uint256 _id, address _makerAsset)
        public
        view
        override
        returns (address, address, uint256, uint256)
    {
        uint orderId;
        uint orderIndex;
        address takerAsset;
        uint makerQuantity;
        uint takerQuantity;
        (orderId, , orderIndex) = Trading(msg.sender).getOpenOrderInfo(_targetExchange, _makerAsset);
        (, takerAsset, makerQuantity, takerQuantity) = Trading(msg.sender).getOrderDetails(orderIndex);
        uint takerAssetFilledAmount = IZeroExV3(_targetExchange).filled(bytes32(orderId));
        uint makerAssetFilledAmount = mul(takerAssetFilledAmount, makerQuantity) / takerQuantity;
        if (IZeroExV3(_targetExchange).cancelled(bytes32(orderId)) || sub(takerQuantity, takerAssetFilledAmount) == 0) {
            return (_makerAsset, takerAsset, 0, 0);
        }
        return (
            _makerAsset,
            takerAsset,
            sub(makerQuantity, makerAssetFilledAmount),
            sub(takerQuantity, takerAssetFilledAmount)
        );
    }

    // INTERNAL METHODS

    /// @notice Approves makerAsset, makerFeeAsset
    function approveAssetsMakeOrder(address _targetExchange, IZeroExV3.Order memory _order)
        internal
    {
        approveAsset(
            getAssetAddress(_order.makerAssetData),
            getAssetProxy(_targetExchange, _order.makerAssetData),
            _order.makerAssetAmount,
            "makerAsset"
        );
        if (_order.makerFee > 0) {
            approveAsset(
                getAssetAddress(_order.makerFeeAssetData),
                getAssetProxy(_targetExchange, _order.makerFeeAssetData),
                _order.makerFee,
                "makerFeeAsset"
            );
        }
    }

    /// @notice Approves takerAsset, takerFeeAsset, protocolFee
    function approveAssetsTakeOrder(address _targetExchange, IZeroExV3.Order memory _order)
        internal
    {
        approveProtocolFeeAsset(_targetExchange);
        approveAsset(
            getAssetAddress(_order.takerAssetData),
            getAssetProxy(_targetExchange, _order.takerAssetData),
            _order.takerAssetAmount,
            "takerAsset"
        );
        if (_order.takerFee > 0) {
            approveAsset(
                getAssetAddress(_order.takerFeeAssetData),
                getAssetProxy(_targetExchange, _order.takerFeeAssetData),
                _order.takerFee,
                "takerFeeAsset"
            );
        }
    }

    function approveProtocolFeeAsset(address _targetExchange) internal {
        address protocolFeeCollector = IZeroExV3(_targetExchange).protocolFeeCollector();
        uint256 protocolFeeAmount = calcProtocolFeeAmount(_targetExchange);
        if (protocolFeeCollector == address(0) || protocolFeeAmount == 0) return;

        Hub hub = getHub();
        address nativeAsset = Accounting(hub.accounting()).NATIVE_ASSET();

        approveAsset(nativeAsset, protocolFeeCollector, protocolFeeAmount, "protocolFee");
    }

    /// @dev Needed to avoid stack too deep error
    function executeFill(
        address _targetExchange,
        IZeroExV3.Order memory _order,
        uint256 _takerAssetFillAmount,
        bytes memory _signature
    )
        internal
        returns (uint256)
    {
        Hub hub = getHub();
        address makerAsset = getAssetAddress(_order.makerAssetData);
        uint preMakerAssetBalance = IERC20(makerAsset).balanceOf(address(this));

        IZeroExV3.FillResults memory fillResults = IZeroExV3(_targetExchange).fillOrder(
            _order,
            _takerAssetFillAmount,
            _signature
        );

        uint256 postMakerAssetBalance = IERC20(makerAsset).balanceOf(address(this));

        // Account for case where makerAsset, takerFee, protocolFee are the same
        uint256 makerAssetFeesTotal;
        if (
            makerAsset == Accounting(hub.accounting()).NATIVE_ASSET() &&
            IZeroExV3(_targetExchange).protocolFeeCollector() != address(0)
        )
        {
            makerAssetFeesTotal = calcProtocolFeeAmount(_targetExchange);
        }
        if (makerAsset == getAssetAddress(_order.takerFeeAssetData)) {
            makerAssetFeesTotal = add(makerAssetFeesTotal, _order.takerFee);
        }

        require(
            postMakerAssetBalance == sub(
                add(preMakerAssetBalance, fillResults.makerAssetFilledAmount),
                makerAssetFeesTotal
            ),
            "Maker asset balance different than expected"
        );

        return fillResults.takerAssetFilledAmount;
    }

    /// @notice Revoke asset approvals and return assets to vault
    function revokeApproveAssetsCancelOrder(
        address _targetExchange,
        IZeroExV3.Order memory _order
    )
        internal
    {
        address makerAsset = getAssetAddress(_order.makerAssetData);
        address makerFeeAsset = getAssetAddress(_order.makerFeeAssetData);
        bytes32 orderHash = IZeroExV3(_targetExchange).getOrderInfo(_order).orderHash;
        uint takerAssetFilledAmount = IZeroExV3(_targetExchange).filled(orderHash);
        uint makerAssetFilledAmount = mul(takerAssetFilledAmount, _order.makerAssetAmount) / _order.takerAssetAmount;
        uint256 makerAssetRemainingInOrder = sub(_order.makerAssetAmount, makerAssetFilledAmount);
        uint256 makerFeeRemainingInOrder = mul(_order.makerFee, makerAssetRemainingInOrder) / _order.makerAssetAmount;

        revokeApproveAsset(
            makerAsset,
            getAssetProxy(_targetExchange, _order.makerAssetData),
            makerAssetRemainingInOrder,
            "makerAsset"
        );
        uint256 timesMakerAssetUsedAsFee = getTrading().openMakeOrdersUsingAssetAsFee(makerAsset);
        // only return makerAsset early when it is not being used as a fee anywhere
        if (timesMakerAssetUsedAsFee == 0) {
            getTrading().returnAssetToVault(makerAsset);
        }

        if (_order.makerFee > 0) {
            revokeApproveAsset(
                makerFeeAsset,
                getAssetProxy(_targetExchange, _order.makerFeeAssetData),
                makerFeeRemainingInOrder,
                "makerFeeAsset"
            );
            // only return feeAsset when not used in another makeOrder AND
            //  when it is only used as a fee in this order that we are cancelling
            uint256 timesFeeAssetUsedAsFee = getTrading().openMakeOrdersUsingAssetAsFee(makerFeeAsset);
            if (
                !getTrading().isInOpenMakeOrder(makerFeeAsset) &&
                timesFeeAssetUsedAsFee == 1
            ) getTrading().returnAssetToVault(makerFeeAsset);
        }
    }

    function updateStateCancelOrder(address _targetExchange, IZeroExV3.Order memory _order)
        internal
    {
        address makerAsset = getAssetAddress(_order.makerAssetData);

        getTrading().removeOpenMakeOrder(_targetExchange, makerAsset);
        getAccounting().updateOwnedAssets();
        getTrading().orderUpdateHook(
            _targetExchange,
            IZeroExV3(_targetExchange).getOrderInfo(_order).orderHash,
            Trading.UpdateType.cancel,
            [address(0), address(0)],
            [uint(0), uint(0), uint(0)]
        );
    }

    function updateStateMakeOrder(address _targetExchange, IZeroExV3.Order memory _order)
        internal
    {
        address makerAsset = getAssetAddress(_order.makerAssetData);
        address takerAsset = getAssetAddress(_order.takerAssetData);
        IZeroExV3.OrderInfo memory orderInfo = IZeroExV3(_targetExchange).getOrderInfo(_order);

        getAccounting().addAssetToOwnedAssets(takerAsset);
        getTrading().orderUpdateHook(
            _targetExchange,
            orderInfo.orderHash,
            Trading.UpdateType.make,
            [payable(makerAsset), payable(takerAsset)],
            [_order.makerAssetAmount, _order.takerAssetAmount, uint(0)]
        );
        getTrading().addOpenMakeOrder(
            _targetExchange,
            makerAsset,
            takerAsset,
            getAssetAddress(_order.makerFeeAssetData),
            uint256(orderInfo.orderHash),
            _order.expirationTimeSeconds
        );
        getTrading().addZeroExV3OrderData(orderInfo.orderHash, _order);
    }

    /// @dev Avoids stack too deep error
    function updateStateTakeOrder(
        address _targetExchange,
        IZeroExV3.Order memory _order,
        uint256 _fillTakerQuantity
    )
        internal
    {
        address makerAsset = getAssetAddress(_order.makerAssetData);
        address takerAsset = getAssetAddress(_order.takerAssetData);

        getAccounting().addAssetToOwnedAssets(makerAsset);
        getAccounting().updateOwnedAssets();
        if (
            !getTrading().isInOpenMakeOrder(makerAsset) &&
            getTrading().openMakeOrdersUsingAssetAsFee(makerAsset) == 0
        ) {
            getTrading().returnAssetToVault(makerAsset);
        }
        getTrading().orderUpdateHook(
            _targetExchange,
            IZeroExV3(_targetExchange).getOrderInfo(_order).orderHash,
            Trading.UpdateType.take,
            [payable(makerAsset), payable(takerAsset)],
            [_order.makerAssetAmount, _order.takerAssetAmount, _fillTakerQuantity]
        );
    }

    // VIEW METHODS
    function calcProtocolFeeAmount(address _targetExchange) internal view returns (uint256) {
        return mul(IZeroExV3(_targetExchange).protocolFeeMultiplier(), tx.gasprice);
    }

    function constructOrderStruct(
        address[8] memory _orderAddresses,
        uint[8] memory _orderValues,
        bytes[4] memory _orderData
    )
        internal
        view
        returns (IZeroExV3.Order memory order_)
    {
        order_ = IZeroExV3.Order({
            makerAddress: _orderAddresses[0],
            takerAddress: _orderAddresses[1],
            feeRecipientAddress: _orderAddresses[4],
            senderAddress: _orderAddresses[5],
            makerAssetAmount: _orderValues[0],
            takerAssetAmount: _orderValues[1],
            makerFee: _orderValues[2],
            takerFee: _orderValues[3],
            expirationTimeSeconds: _orderValues[4],
            salt: _orderValues[5],
            makerAssetData: _orderData[0],
            takerAssetData: _orderData[1],
            makerFeeAssetData: _orderData[2],
            takerFeeAssetData: _orderData[3]
        });
    }

    function getAssetProxy(address _targetExchange, bytes memory _assetData)
        internal
        view
        returns (address assetProxy_)
    {
        bytes4 assetProxyId;
        assembly {
            assetProxyId := and(mload(
                add(_assetData, 32)),
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }
        assetProxy_ = IZeroExV3(_targetExchange).getAssetProxy(assetProxyId);
    }

    function getAssetAddress(bytes memory _assetData)
        internal
        view
        returns (address assetAddress_)
    {
        assembly {
            assetAddress_ := mload(add(_assetData, 36))
        }
    }
}

contract ZeroExV2Adapter is DSMath, ExchangeAdapter {
    /// @param orderAddresses [2] Order maker asset
    /// @param orderAddresses [3] Order taker asset
    /// @param orderData [0] Order maker asset data
    /// @param orderData [1] Order taker asset data
    modifier orderAddressesMatchOrderData(
        address[8] memory orderAddresses,
        bytes[4] memory orderData
    )
    {
        require(
            getAssetAddress(orderData[0]) == orderAddresses[2],
            "Maker asset data does not match order address in array"
        );
        require(
            getAssetAddress(orderData[1]) == orderAddresses[3],
            "Taker asset data does not match order address in array"
        );
        _;
    }

    //  METHODS

    //  PUBLIC METHODS

    /// @notice Make order by pre-approving signatures
    function makeOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    )
        public
        override
        onlyManager
        notShutDown
        orderAddressesMatchOrderData(orderAddresses, orderData)
    {
        ensureCanMakeOrder(orderAddresses[2]);

        IZeroExV2.Order memory order = constructOrderStruct(orderAddresses, orderValues, orderData);
        address makerAsset = getAssetAddress(orderData[0]);
        address takerAsset = getAssetAddress(orderData[1]);

        // Order parameter checks
        getTrading().updateAndGetQuantityBeingTraded(makerAsset);
        ensureNotInOpenMakeOrder(makerAsset);

        approveAssetsMakeOrder(targetExchange, order);

        IZeroExV2.OrderInfo memory orderInfo = IZeroExV2(targetExchange).getOrderInfo(order);
        IZeroExV2(targetExchange).preSign(orderInfo.orderHash, address(this), signature);

        require(
            IZeroExV2(targetExchange).isValidSignature(
                orderInfo.orderHash,
                address(this),
                signature
            ),
            "INVALID_ORDER_SIGNATURE"
        );

        updateStateMakeOrder(targetExchange, order);
    }

    // Responsibilities of takeOrder are:
    // - check sender
    // - check fund not shut down
    // - check not buying own fund tokens
    // - check price exists for asset pair
    // - check price is recent
    // - check price passes risk management
    // - approve funds to be traded (if necessary)
    // - take order from the exchange
    // - check order was taken (if possible)
    // - place asset in ownedAssets if not already tracked
    /// @notice Takes an active order on the selected exchange
    /// @dev These orders are expected to settle immediately
    /// @param targetExchange Address of the exchange
    /// @param orderAddresses [0] Order maker
    /// @param orderAddresses [1] Order taker
    /// @param orderAddresses [2] Order maker asset
    /// @param orderAddresses [3] Order taker asset
    /// @param orderAddresses [4] feeRecipientAddress
    /// @param orderAddresses [5] senderAddress
    /// @param orderValues [0] makerAssetAmount
    /// @param orderValues [1] takerAssetAmount
    /// @param orderValues [2] Maker fee
    /// @param orderValues [3] Taker fee
    /// @param orderValues [4] expirationTimeSeconds
    /// @param orderValues [5] Salt/nonce
    /// @param orderValues [6] Fill amount: amount of taker token to be traded
    /// @param orderValues [7] Dexy signature mode
    /// @param orderData [0] Encoded data specific to maker asset
    /// @param orderData [1] Encoded data specific to taker asset
    /// @param orderData [2] Encoded data specific to maker asset fee
    /// @param orderData [3] Encoded data specific to taker asset fee
    /// @param identifier Order identifier
    /// @param signature Signature of the order.
    function takeOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    )
        public
        override
        onlyManager
        notShutDown
        orderAddressesMatchOrderData(orderAddresses, orderData)
    {
        IZeroExV2.Order memory order = constructOrderStruct(orderAddresses, orderValues, orderData);

        uint fillTakerQuantity = orderValues[6];

        approveAssetsTakeOrder(targetExchange, order);

        uint takerAssetFilledAmount = executeFill(targetExchange, order, fillTakerQuantity, signature);
        require(
            takerAssetFilledAmount == fillTakerQuantity,
            "Filled amount does not match desired fill amount"
        );

        updateStateTakeOrder(targetExchange, order, fillTakerQuantity);
    }

    /// @notice Cancel the 0x make order
    function cancelOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    )
        public
        override
        orderAddressesMatchOrderData(orderAddresses, orderData)
    {
        IZeroExV2.Order memory order = getTrading().getZeroExV2OrderDetails(identifier);
        ensureCancelPermitted(targetExchange, orderAddresses[2], identifier);

        if (order.expirationTimeSeconds > block.timestamp) {
            IZeroExV2(targetExchange).cancelOrder(order);
        }

        revokeApproveAssetsCancelOrder(targetExchange, order);

        updateStateCancelOrder(targetExchange, order);
    }

    /// @dev Get order details
    function getOrder(address targetExchange, uint256 id, address makerAsset)
        public
        view
        override
        returns (address, address, uint256, uint256)
    {
        uint orderId;
        uint orderIndex;
        address takerAsset;
        uint makerQuantity;
        uint takerQuantity;
        (orderId, , orderIndex) = Trading(msg.sender).getOpenOrderInfo(targetExchange, makerAsset);
        (, takerAsset, makerQuantity, takerQuantity) = Trading(msg.sender).getOrderDetails(orderIndex);
        uint takerAssetFilledAmount = IZeroExV2(targetExchange).filled(bytes32(orderId));
        uint makerAssetFilledAmount = mul(takerAssetFilledAmount, makerQuantity) / takerQuantity;
        if (IZeroExV2(targetExchange).cancelled(bytes32(orderId)) || sub(takerQuantity, takerAssetFilledAmount) == 0) {
            return (makerAsset, takerAsset, 0, 0);
        }
        return (
            makerAsset,
            takerAsset,
            sub(makerQuantity, makerAssetFilledAmount),
            sub(takerQuantity, takerAssetFilledAmount)
        );
    }

    // INTERNAL METHODS

    /// @notice Approves makerAsset, makerFee
    function approveAssetsMakeOrder(address _targetExchange, IZeroExV2.Order memory _order)
        internal
    {
        approveAsset(
            getAssetAddress(_order.makerAssetData),
            getAssetProxy(_targetExchange, _order.makerAssetData),
            _order.makerAssetAmount,
            "makerAsset"
        );
        if (_order.makerFee > 0) {
            bytes memory zrxAssetData = IZeroExV2(_targetExchange).ZRX_ASSET_DATA();
            approveAsset(
                getAssetAddress(zrxAssetData),
                getAssetProxy(_targetExchange, zrxAssetData),
                _order.makerFee,
                "makerFeeAsset"
            );
        }
    }

    /// @notice Approves takerAsset, takerFee
    function approveAssetsTakeOrder(address _targetExchange, IZeroExV2.Order memory _order)
        internal
    {
        approveAsset(
            getAssetAddress(_order.takerAssetData),
            getAssetProxy(_targetExchange, _order.takerAssetData),
            _order.takerAssetAmount,
            "takerAsset"
        );
        if (_order.takerFee > 0) {
            bytes memory zrxAssetData = IZeroExV2(_targetExchange).ZRX_ASSET_DATA();
            approveAsset(
                getAssetAddress(zrxAssetData),
                getAssetProxy(_targetExchange, zrxAssetData),
                _order.takerFee,
                "takerFeeAsset"
            );
        }
    }

    /// @dev Needed to avoid stack too deep error
    function executeFill(
        address targetExchange,
        IZeroExV2.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        internal
        returns (uint256)
    {
        address makerAsset = getAssetAddress(order.makerAssetData);
        uint preMakerAssetBalance = IERC20(makerAsset).balanceOf(address(this));

        IZeroExV2.FillResults memory fillResults = IZeroExV2(targetExchange).fillOrder(
            order,
            takerAssetFillAmount,
            signature
        );

        uint256 postMakerAssetBalance = IERC20(makerAsset).balanceOf(address(this));

        // Account for case where makerAsset is ZRX (same as takerFee)
        uint256 makerAssetFeesTotal;
        if (makerAsset == getAssetAddress(IZeroExV2(targetExchange).ZRX_ASSET_DATA())) {
            makerAssetFeesTotal = add(makerAssetFeesTotal, order.takerFee);
        }

        require(
            postMakerAssetBalance == sub(
                add(preMakerAssetBalance, fillResults.makerAssetFilledAmount),
                makerAssetFeesTotal
            ),
            "Maker asset balance different than expected"
        );

        return fillResults.takerAssetFilledAmount;
    }

    /// @notice Revoke asset approvals and return assets to vault
    function revokeApproveAssetsCancelOrder(
        address _targetExchange,
        IZeroExV2.Order memory _order
    )
        internal
    {
        address makerAsset = getAssetAddress(_order.makerAssetData);
        bytes memory makerFeeAssetData = IZeroExV2(_targetExchange).ZRX_ASSET_DATA();
        address makerFeeAsset = getAssetAddress(makerFeeAssetData);
        bytes32 orderHash = IZeroExV2(_targetExchange).getOrderInfo(_order).orderHash;
        uint takerAssetFilledAmount = IZeroExV2(_targetExchange).filled(orderHash);
        uint makerAssetFilledAmount = mul(takerAssetFilledAmount, _order.makerAssetAmount) / _order.takerAssetAmount;
        uint256 makerAssetRemainingInOrder = sub(_order.makerAssetAmount, makerAssetFilledAmount);
        uint256 makerFeeRemainingInOrder = mul(_order.makerFee, makerAssetRemainingInOrder) / _order.makerAssetAmount;

        revokeApproveAsset(
            makerAsset,
            getAssetProxy(_targetExchange, _order.makerAssetData),
            makerAssetRemainingInOrder,
            "makerAsset"
        );
        uint256 timesMakerAssetUsedAsFee = getTrading().openMakeOrdersUsingAssetAsFee(makerAsset);
        // only return makerAsset early when it is not being used as a fee anywhere
        if (timesMakerAssetUsedAsFee == 0) {
            getTrading().returnAssetToVault(makerAsset);
        }

        if (_order.makerFee > 0) {
            revokeApproveAsset(
                makerFeeAsset,
                getAssetProxy(_targetExchange, makerFeeAssetData),
                makerFeeRemainingInOrder,
                "makerFeeAsset"
            );
            // only return feeAsset when not used in another makeOrder AND
            //  when it is only used as a fee in this order that we are cancelling
            uint256 timesFeeAssetUsedAsFee = getTrading().openMakeOrdersUsingAssetAsFee(makerFeeAsset);
            if (
                !getTrading().isInOpenMakeOrder(makerFeeAsset) &&
                timesFeeAssetUsedAsFee == 1
            ) {
                getTrading().returnAssetToVault(makerFeeAsset);
            }
        }
    }

    /// @dev Avoids stack too deep error
    function updateStateCancelOrder(address targetExchange, IZeroExV2.Order memory order)
        internal
    {
        address makerAsset = getAssetAddress(order.makerAssetData);

        getTrading().removeOpenMakeOrder(targetExchange, makerAsset);
        getAccounting().updateOwnedAssets();
        getTrading().orderUpdateHook(
            targetExchange,
            IZeroExV2(targetExchange).getOrderInfo(order).orderHash,
            Trading.UpdateType.cancel,
            [address(0), address(0)],
            [uint(0), uint(0), uint(0)]
        );
    }

    /// @dev Avoids stack too deep error
    function updateStateMakeOrder(address targetExchange, IZeroExV2.Order memory order)
        internal
    {
        address makerAsset = getAssetAddress(order.makerAssetData);
        address takerAsset = getAssetAddress(order.takerAssetData);
        IZeroExV2.OrderInfo memory orderInfo = IZeroExV2(targetExchange).getOrderInfo(order);

        getAccounting().addAssetToOwnedAssets(takerAsset);
        getTrading().orderUpdateHook(
            targetExchange,
            orderInfo.orderHash,
            Trading.UpdateType.make,
            [payable(makerAsset), payable(takerAsset)],
            [order.makerAssetAmount, order.takerAssetAmount, uint(0)]
        );
        getTrading().addOpenMakeOrder(
            targetExchange,
            makerAsset,
            takerAsset,
            getAssetAddress(IZeroExV2(targetExchange).ZRX_ASSET_DATA()),
            uint256(orderInfo.orderHash),
            order.expirationTimeSeconds
        );
        getTrading().addZeroExV2OrderData(orderInfo.orderHash, order);
    }

    /// @dev avoids stack too deep error
    function updateStateTakeOrder(
        address targetExchange,
        IZeroExV2.Order memory order,
        uint256 fillTakerQuantity
    )
        internal
    {
        address makerAsset = getAssetAddress(order.makerAssetData);
        address takerAsset = getAssetAddress(order.takerAssetData);

        getAccounting().addAssetToOwnedAssets(makerAsset);
        getAccounting().updateOwnedAssets();
        if (
            !getTrading().isInOpenMakeOrder(makerAsset) &&
            getTrading().openMakeOrdersUsingAssetAsFee(makerAsset) == 0
        ) {
            getTrading().returnAssetToVault(makerAsset);
        }
        getTrading().orderUpdateHook(
            targetExchange,
            IZeroExV2(targetExchange).getOrderInfo(order).orderHash,
            Trading.UpdateType.take,
            [payable(makerAsset), payable(takerAsset)],
            [order.makerAssetAmount, order.takerAssetAmount, fillTakerQuantity]
        );
    }

    // VIEW METHODS

    function constructOrderStruct(
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData
    )
        internal
        view
        returns (IZeroExV2.Order memory order)
    {
        order = IZeroExV2.Order({
            makerAddress: orderAddresses[0],
            takerAddress: orderAddresses[1],
            feeRecipientAddress: orderAddresses[4],
            senderAddress: orderAddresses[5],
            makerAssetAmount: orderValues[0],
            takerAssetAmount: orderValues[1],
            makerFee: orderValues[2],
            takerFee: orderValues[3],
            expirationTimeSeconds: orderValues[4],
            salt: orderValues[5],
            makerAssetData: orderData[0],
            takerAssetData: orderData[1]
        });
    }

    function getAssetProxy(address targetExchange, bytes memory assetData)
        internal
        view
        returns (address assetProxy)
    {
        bytes4 assetProxyId;
        assembly {
            assetProxyId := and(mload(
                add(assetData, 32)),
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }
        assetProxy = IZeroExV2(targetExchange).getAssetProxy(assetProxyId);
    }

    function getAssetAddress(bytes memory assetData)
        internal
        view
        returns (address assetAddress)
    {
        assembly {
            assetAddress := mload(add(assetData, 36))
        }
    }
}

contract UniswapAdapter is DSMath, ExchangeAdapter {
    /// @notice Take order that uses a user-defined src token amount to trade for a dest token amount
    /// @dev For the purpose of PriceTolerance, _orderValues [1] == _orderValues [6] = Dest token amount
    /// @param _targetExchange Address of Uniswap factory contract
    /// @param _orderAddresses [2] Maker asset (Dest token)
    /// @param _orderAddresses [3] Taker asset (Src token)
    /// @param _orderValues [0] Maker asset quantity (Dest token amount)
    /// @param _orderValues [1] Taker asset quantity (Src token amount)
    /// @param _orderValues [6] Taker asset fill amount
    function takeOrder(
        address _targetExchange,
        address[8] memory _orderAddresses,
        uint[8] memory _orderValues,
        bytes[4] memory _orderData,
        bytes32 _identifier,
        bytes memory _signature
    )
        public
        override
        onlyManager
        notShutDown
    {
        Hub hub = getHub();

        require(
            _orderValues[1] == _orderValues[6],
            "Taker asset amount must equal taker asset fill amount"
        );

        address makerAsset = _orderAddresses[2];
        address takerAsset = _orderAddresses[3];
        uint makerAssetAmount = _orderValues[0];
        uint takerAssetAmount = _orderValues[1];

        uint actualReceiveAmount = dispatchSwap(
            _targetExchange, takerAsset, takerAssetAmount, makerAsset, makerAssetAmount
        );
        require(
            actualReceiveAmount >= makerAssetAmount,
            "Received less than expected from Uniswap exchange"
        );

        updateStateTakeOrder(
            _targetExchange,
            makerAsset,
            takerAsset,
            takerAssetAmount,
            actualReceiveAmount
        );
    }

    // INTERNAL FUNCTIONS

    /// @notice Call different functions based on type of assets supplied
    /// @param _targetExchange Address of Uniswap factory contract
    /// @param _srcToken Address of src token
    /// @param _srcAmount Amount of src token supplied
    /// @param _destToken Address of dest token
    /// @param _minDestAmount Minimum amount of dest token to receive
    /// @return actualReceiveAmount_ Actual amount of _destToken received
    function dispatchSwap(
        address _targetExchange,
        address _srcToken,
        uint _srcAmount,
        address _destToken,
        uint _minDestAmount
    )
        internal
        returns (uint actualReceiveAmount_)
    {
        require(
            _srcToken != _destToken,
            "Src token cannot be the same as dest token"
        );

        Hub hub = getHub();
        address nativeAsset = Accounting(hub.accounting()).NATIVE_ASSET();

        if (_srcToken == nativeAsset) {
            actualReceiveAmount_ = swapNativeAssetToToken(
                _targetExchange,
                nativeAsset,
                _srcAmount,
                _destToken,
                _minDestAmount
            );
        } else if (_destToken == nativeAsset) {
            actualReceiveAmount_ = swapTokenToNativeAsset(
                _targetExchange,
                _srcToken,
                _srcAmount,
                nativeAsset,
                _minDestAmount
            );
        } else {
            actualReceiveAmount_ = swapTokenToToken(
                _targetExchange,
                _srcToken,
                _srcAmount,
                _destToken,
                _minDestAmount
            );
        }
    }

    /// @param _targetExchange Address of Uniswap factory contract
    /// @param _nativeAsset Native asset address as src token
    /// @param _srcAmount Amount of native asset supplied
    /// @param _destToken Address of dest token
    /// @param _minDestAmount Minimum amount of dest token to get back
    /// @return actualReceiveAmount_ Actual amount of _destToken received
    function swapNativeAssetToToken(
        address _targetExchange,
        address _nativeAsset,
        uint _srcAmount,
        address _destToken,
        uint _minDestAmount
    )
        internal
        returns (uint actualReceiveAmount_)
    {
        // Convert WETH to ETH
        Hub hub = getHub();
        Vault vault = Vault(hub.vault());
        vault.withdraw(_nativeAsset, _srcAmount);
        WETH(payable(_nativeAsset)).withdraw(_srcAmount);

        address tokenExchange = IUniswapFactory(_targetExchange).getExchange(_destToken);
        actualReceiveAmount_ = IUniswapExchange(tokenExchange).ethToTokenTransferInput.value(
            _srcAmount
        )
        (
            _minDestAmount,
            add(block.timestamp, 1),
            address(vault)
        );
    }

    /// @param _targetExchange Address of Uniswap factory contract
    /// @param _srcToken Address of src token
    /// @param _srcAmount Amount of src token supplied
    /// @param _nativeAsset Native asset address as dest token
    /// @param _minDestAmount Minimum amount of dest token to get back
    /// @return actualReceiveAmount_ Actual amount of _destToken received
    function swapTokenToNativeAsset(
        address _targetExchange,
        address _srcToken,
        uint _srcAmount,
        address _nativeAsset,
        uint _minDestAmount
    )
        internal
        returns (uint actualReceiveAmount_)
    {
        Hub hub = getHub();
        Vault vault = Vault(hub.vault());
        vault.withdraw(_srcToken, _srcAmount);

        address tokenExchange = IUniswapFactory(_targetExchange).getExchange(_srcToken);
        approveAsset(_srcToken, tokenExchange, _srcAmount, "takerAsset");
        actualReceiveAmount_ = IUniswapExchange(tokenExchange).tokenToEthSwapInput(
            _srcAmount,
            _minDestAmount,
            add(block.timestamp, 1)
        );

        // Convert ETH to WETH and move to Vault
        WETH(payable(_nativeAsset)).deposit.value(actualReceiveAmount_)();
        uint256 timesNativeAssetUsedAsFee = getTrading().openMakeOrdersUsingAssetAsFee(_nativeAsset);
        if (
            !getTrading().isInOpenMakeOrder(_nativeAsset) &&
            timesNativeAssetUsedAsFee == 0
        ) {
            getTrading().returnAssetToVault(_nativeAsset);
        }
    }

    /// @param _targetExchange Address of Uniswap factory contract
    /// @param _srcToken Address of src token
    /// @param _srcAmount Amount of src token supplied
    /// @param _destToken Address of dest token
    /// @param _minDestAmount Minimum amount of dest token to get back
    /// @return actualReceiveAmount_ Actual amount of _destToken received
    function swapTokenToToken(
        address _targetExchange,
        address _srcToken,
        uint _srcAmount,
        address _destToken,
        uint _minDestAmount
    )
        internal
        returns (uint actualReceiveAmount_)
    {
        Hub hub = getHub();
        Vault vault = Vault(hub.vault());
        vault.withdraw(_srcToken, _srcAmount);

        address tokenExchange = IUniswapFactory(_targetExchange).getExchange(_srcToken);
        approveAsset(_srcToken, tokenExchange, _srcAmount, "takerAsset");
        actualReceiveAmount_ = IUniswapExchange(tokenExchange).tokenToTokenTransferInput(
            _srcAmount,
            _minDestAmount,
            1,
            add(block.timestamp, 1),
            address(vault),
            _destToken
        );
    }

    function updateStateTakeOrder(
        address _targetExchange,
        address _makerAsset,
        address _takerAsset,
        uint256 _takerAssetAmount,
        uint256 _actualReceiveAmount
    )
        internal
    {
        getAccounting().addAssetToOwnedAssets(_makerAsset);
        getAccounting().updateOwnedAssets();
        getTrading().orderUpdateHook(
            _targetExchange,
            bytes32(0),
            Trading.UpdateType.take,
            [payable(_makerAsset), payable(_takerAsset)],
            [_actualReceiveAmount, _takerAssetAmount, _takerAssetAmount]
        );
    }
}

contract OasisDexAdapter is DSMath, ExchangeAdapter {

    event OrderCreated(uint256 id);

    //  METHODS

    //  PUBLIC METHODS

    // Responsibilities of makeOrder are:
    // - check sender
    // - check fund not shut down
    // - check price recent
    // - check risk management passes
    // - approve funds to be traded (if necessary)
    // - make order on the exchange
    // - check order was made (if possible)
    // - place asset in ownedAssets if not already tracked
    /// @notice Makes an order on the selected exchange
    /// @dev These orders are not expected to settle immediately
    /// @param targetExchange Address of the exchange
    /// @param orderAddresses [2] Order maker asset
    /// @param orderAddresses [3] Order taker asset
    /// @param orderValues [0] Maker token quantity
    /// @param orderValues [1] Taker token quantity
    function makeOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public override onlyManager notShutDown {
        ensureCanMakeOrder(orderAddresses[2]);
        address makerAsset = orderAddresses[2];
        address takerAsset = orderAddresses[3];
        uint256 makerQuantity = orderValues[0];
        uint256 takerQuantity = orderValues[1];

        // Order parameter checks
        getTrading().updateAndGetQuantityBeingTraded(makerAsset);
        ensureNotInOpenMakeOrder(makerAsset);

        approveAsset(makerAsset, targetExchange, makerQuantity, "makerAsset");

        uint256 orderId = IOasisDex(targetExchange).offer(makerQuantity, makerAsset, takerQuantity, takerAsset);

        // defines success in MatchingMarket
        require(orderId != 0, "Order ID should not be zero");

        getAccounting().addAssetToOwnedAssets(takerAsset);
        getTrading().orderUpdateHook(
            targetExchange,
            bytes32(orderId),
            Trading.UpdateType.make,
            [payable(makerAsset), payable(takerAsset)],
            [makerQuantity, takerQuantity, uint256(0)]
        );
        getTrading().addOpenMakeOrder(
            targetExchange,
            makerAsset,
            takerAsset,
            address(0),
            orderId,
            orderValues[4]
        );
        emit OrderCreated(orderId);
    }

    // Responsibilities of takeOrder are:
    // - check sender
    // - check fund not shut down
    // - check not buying own fund tokens
    // - check price exists for asset pair
    // - check price is recent
    // - check price passes risk management
    // - approve funds to be traded (if necessary)
    // - take order from the exchange
    // - check order was taken (if possible)
    // - place asset in ownedAssets if not already tracked
    /// @notice Takes an active order on the selected exchange
    /// @dev These orders are expected to settle immediately
    /// @param targetExchange Address of the exchange
    /// @param orderValues [6] Fill amount : amount of taker token to fill
    /// @param identifier Active order id
    function takeOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public override onlyManager notShutDown {
        Hub hub = getHub();
        uint256 fillTakerQuantity = orderValues[6];
        uint256 maxMakerQuantity;
        address makerAsset;
        uint256 maxTakerQuantity;
        address takerAsset;
        (
            maxMakerQuantity,
            makerAsset,
            maxTakerQuantity,
            takerAsset
        ) = IOasisDex(targetExchange).getOffer(uint256(identifier));
        uint256 fillMakerQuantity = mul(fillTakerQuantity, maxMakerQuantity) / maxTakerQuantity;

        require(
            makerAsset == orderAddresses[2] && takerAsset == orderAddresses[3],
            "Maker and taker assets do not match the order addresses"
        );
        require(
            makerAsset != takerAsset,
            "Maker and taker assets cannot be the same"
        );
        require(fillMakerQuantity <= maxMakerQuantity, "Maker amount to fill above max");
        require(fillTakerQuantity <= maxTakerQuantity, "Taker amount to fill above max");

        approveAsset(takerAsset, targetExchange, fillTakerQuantity, "takerAsset");

        require(
            IOasisDex(targetExchange).buy(uint256(identifier), fillMakerQuantity),
            "Buy on matching market failed"
        );

        getAccounting().addAssetToOwnedAssets(makerAsset);
        getAccounting().updateOwnedAssets();
        uint256 timesMakerAssetUsedAsFee = getTrading().openMakeOrdersUsingAssetAsFee(makerAsset);
        if (
            !getTrading().isInOpenMakeOrder(makerAsset) &&
            timesMakerAssetUsedAsFee == 0
        ) {
            getTrading().returnAssetToVault(makerAsset);
        }
        getTrading().orderUpdateHook(
            targetExchange,
            bytes32(identifier),
            Trading.UpdateType.take,
            [payable(makerAsset), payable(takerAsset)],
            [maxMakerQuantity, maxTakerQuantity, fillTakerQuantity]
        );
    }

    // responsibilities of cancelOrder are:
    // - check sender is owner, or that order expired, or that fund shut down
    // - remove order from tracking array
    // - cancel order on exchange
    /// @notice Cancels orders that were not expected to settle immediately
    /// @param targetExchange Address of the exchange
    /// @param orderAddresses [2] Order maker asset
    /// @param identifier Order ID on the exchange
    function cancelOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public override {
        require(uint256(identifier) != 0, "ID cannot be zero");
        address makerAsset;
        (, makerAsset, ,) = IOasisDex(targetExchange).getOffer(uint256(identifier));
        ensureCancelPermitted(targetExchange, makerAsset, identifier);

        require(
            address(makerAsset) == orderAddresses[2],
            "Retrieved and passed assets do not match"
        );

        getTrading().removeOpenMakeOrder(targetExchange, makerAsset);
        IOasisDex(targetExchange).cancel(uint256(identifier));
        uint256 timesMakerAssetUsedAsFee = getTrading().openMakeOrdersUsingAssetAsFee(makerAsset);
        if (timesMakerAssetUsedAsFee == 0) {
            getTrading().returnAssetToVault(makerAsset);
        }
        getAccounting().updateOwnedAssets();
        getTrading().orderUpdateHook(
            targetExchange,
            bytes32(identifier),
            Trading.UpdateType.cancel,
            [address(0), address(0)],
            [uint256(0), uint256(0), uint256(0)]
        );
    }

    // VIEW METHODS

    function getOrder(address targetExchange, uint256 id, address makerAsset)
        public
        view
        override
        returns (address, address, uint256, uint256)
    {
        uint256 sellQuantity;
        address sellAsset;
        uint256 buyQuantity;
        address buyAsset;
        (
            sellQuantity,
            sellAsset,
            buyQuantity,
            buyAsset
        ) = IOasisDex(targetExchange).getOffer(id);
        return (
            sellAsset,
            buyAsset,
            sellQuantity,
            buyQuantity
        );
    }
}

contract OasisDexAccessor {
    function getUnsortedOfferIds(
        address targetExchange,
        address sellAsset,
        address buyAsset
    )
    public
    view
    returns (uint[] memory)
    {
        IOasisDex market = IOasisDex(targetExchange);
        uint[] memory ids = new uint[](1000);
        uint count = 0;

        // Iterate over all unsorted offers up to 1000 iterations.
        uint id = market.getFirstUnsortedOffer();
        for (uint i = 0; i < 1000; i++) {
            if (id == 0) {
                break;
            }

            if (market.isActive(id)) {
                address sellGem;
                address buyGem;
                (, sellGem, , buyGem) = market.getOffer(id);

                if (sellGem == sellAsset && buyGem == buyAsset) {
                    ids[count++] = id;
                }
            }

            // Get the next offer and repeat.
            id = market.getNextUnsortedOffer(id);
        }

        // Create a new array of offers with the correct size.
        uint[] memory copy = new uint[](count);
        for (uint i = 0; i < count; i++) {
            copy[i] = ids[i];
        }

        return copy;
    }

    function getSortedOfferIds(
        address targetExchange,
        address sellAsset,
        address buyAsset
    )
    public
    view
    returns(uint[] memory)
    {
        IOasisDex market = IOasisDex(targetExchange);
        uint[] memory ids = new uint[](1000);
        uint count = 0;

        // Iterate over all sorted offers.
        uint id = market.getBestOffer(sellAsset, buyAsset);
        for (uint i = 0; i < 1000 ; i++ ) {
            if (id == 0) {
                break;
            }

            if (market.isActive(id)) {
                ids[count++] = id;
            }

            // Get the next offer and repeat.
            id = market.getWorseOffer(id);
        }

        // Create a new array of offers with the correct size.
        uint[] memory copy = new uint[](count);
        for (uint i = 0; i < count; i++) {
            copy[i] = ids[i];
        }

        return copy;
    }

    function getOrders(
        address targetExchange,
        address sellAsset,
        address buyAsset
    )
    public
    view
    returns (uint[] memory, uint[] memory, uint[] memory) {
        IOasisDex market = IOasisDex(targetExchange);
        uint[] memory sIds = getSortedOfferIds(targetExchange, sellAsset, buyAsset);
        uint[] memory uIds = getUnsortedOfferIds(targetExchange, sellAsset, buyAsset);
        uint[] memory ids = new uint[](uIds.length + sIds.length);
        uint[] memory sellQtys = new uint[](ids.length);
        uint[] memory buyQtys = new uint[](ids.length);

        for (uint i = 0; i < sIds.length; i++) {
            ids[i] = sIds[i];
        }

        for (uint i = 0; i < uIds.length; i++) {
            ids[i + sIds.length] = uIds[i];
        }

        for (uint i = 0; i < ids.length; i++) {
            uint sellQty;
            uint buyQty;
            (sellQty, , buyQty,) = market.getOffer(ids[i]);
            sellQtys[i] = sellQty;
            buyQtys[i] = buyQty;
        }

        return (ids, sellQtys, buyQtys);
    }
}

contract KyberAdapter is DSMath, ExchangeAdapter {
    address public constant ETH_TOKEN_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    // NON-CONSTANT METHODS

    // Responsibilities of takeOrder (Kybers swapToken) are:
    // - check price recent
    // - check risk management passes
    // - approve funds to be traded (if necessary)
    // - perform swap order on the exchange
    // - place asset in ownedAssets if not already tracked
    /// @notice Swaps srcAmount of srcToken for destAmount of destToken
    /// @dev Variable naming to be close to Kyber's naming
    /// @dev For the purpose of PriceTolerance, fillTakerQuantity == takerAssetQuantity = Dest token amount
    /// @param targetExchange Address of the exchange
    /// @param orderAddresses [2] Maker asset (Dest token)
    /// @param orderAddresses [3] Taker asset (Src token)
    /// @param orderValues [0] Maker asset quantity (Dest token amount)
    /// @param orderValues [1] Taker asset quantity (Src token amount)
    function takeOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public override onlyManager notShutDown {
        Hub hub = getHub();

        require(
            orderValues[1] == orderValues[6],
            "fillTakerQuantity must equal takerAssetQuantity"
        );

        address makerAsset = orderAddresses[2];
        address takerAsset = orderAddresses[3];
        uint makerAssetAmount = orderValues[0];
        uint takerAssetAmount = orderValues[1];

        uint minRate = calcMinRate(
            takerAsset,
            makerAsset,
            takerAssetAmount,
            makerAssetAmount
        );

        uint actualReceiveAmount = dispatchSwap(
            targetExchange, takerAsset, takerAssetAmount, makerAsset, minRate
        );
        require(
            actualReceiveAmount >= makerAssetAmount,
            "Received less than expected from Kyber swap"
        );

        getAccounting().addAssetToOwnedAssets(makerAsset);
        getAccounting().updateOwnedAssets();
        uint256 timesMakerAssetUsedAsFee = getTrading().openMakeOrdersUsingAssetAsFee(makerAsset);
        if (
            !getTrading().isInOpenMakeOrder(makerAsset) &&
            timesMakerAssetUsedAsFee == 0
        ) {
            getTrading().returnAssetToVault(makerAsset);
        }
        getTrading().orderUpdateHook(
            targetExchange,
            bytes32(0),
            Trading.UpdateType.take,
            [payable(makerAsset), payable(takerAsset)],
            [actualReceiveAmount, takerAssetAmount, takerAssetAmount]
        );
    }

    // INTERNAL FUNCTIONS

    /// @notice Call different functions based on type of assets supplied
    function dispatchSwap(
        address targetExchange,
        address srcToken,
        uint srcAmount,
        address destToken,
        uint minRate
    )
        internal
        returns (uint actualReceiveAmount)
    {

        Hub hub = getHub();
        address nativeAsset = Accounting(hub.accounting()).NATIVE_ASSET();

        if (srcToken == nativeAsset) {
            actualReceiveAmount = swapNativeAssetToToken(targetExchange, nativeAsset, srcAmount, destToken, minRate);
        }
        else if (destToken == nativeAsset) {
            actualReceiveAmount = swapTokenToNativeAsset(targetExchange, srcToken, srcAmount, nativeAsset, minRate);
        }
        else {
            actualReceiveAmount = swapTokenToToken(targetExchange, srcToken, srcAmount, destToken, minRate);
        }
    }

    /// @dev If minRate is not defined, uses expected rate from the network
    /// @param targetExchange Address of Kyber proxy contract
    /// @param nativeAsset Native asset address as src token
    /// @param srcAmount Amount of native asset supplied
    /// @param destToken Address of dest token
    /// @param minRate Minimum rate supplied to the Kyber proxy
    /// @return receivedAmount Actual amount of destToken received from the exchange
    function swapNativeAssetToToken(
        address targetExchange,
        address nativeAsset,
        uint srcAmount,
        address destToken,
        uint minRate
    )
        internal
        returns (uint receivedAmount)
    {
        // Convert WETH to ETH
        Hub hub = getHub();
        Vault vault = Vault(hub.vault());
        vault.withdraw(nativeAsset, srcAmount);
        WETH(payable(nativeAsset)).withdraw(srcAmount);
        receivedAmount = IKyberNetworkProxy(targetExchange).swapEtherToToken.value(srcAmount)(destToken, minRate);
    }

    /// @dev If minRate is not defined, uses expected rate from the network
    /// @param targetExchange Address of Kyber proxy contract
    /// @param srcToken Address of src token
    /// @param srcAmount Amount of src token supplied
    /// @param nativeAsset Native asset address as src token
    /// @param minRate Minimum rate supplied to the Kyber proxy
    /// @return receivedAmount Actual amount of destToken received from the exchange
    function swapTokenToNativeAsset(
        address targetExchange,
        address srcToken,
        uint srcAmount,
        address nativeAsset,
        uint minRate
    )
        internal
        returns (uint receivedAmount)
    {
        approveAsset(srcToken, targetExchange, srcAmount, "takerAsset");
        receivedAmount = IKyberNetworkProxy(targetExchange).swapTokenToEther(srcToken, srcAmount, minRate);

        // Convert ETH to WETH
        WETH(payable(nativeAsset)).deposit.value(receivedAmount)();
    }

    /// @dev If minRate is not defined, uses expected rate from the network
    /// @param targetExchange Address of Kyber proxy contract
    /// @param srcToken Address of src token
    /// @param srcAmount Amount of src token supplied
    /// @param destToken Address of dest token
    /// @param minRate Minimum rate supplied to the Kyber proxy
    /// @return receivedAmount Actual amount of destToken received from the exchange
    function swapTokenToToken(
        address targetExchange,
        address srcToken,
        uint srcAmount,
        address destToken,
        uint minRate
    )
        internal
        returns (uint receivedAmount)
    {
        approveAsset(srcToken, targetExchange, srcAmount, "takerAsset");

        receivedAmount = IKyberNetworkProxy(targetExchange).swapTokenToToken(srcToken, srcAmount, destToken, minRate);
    }

    /// @param srcToken Address of src token
    /// @param destToken Address of dest token
    /// @param srcAmount Amount of src token
    /// @return minRate Minimum rate to be supplied to the network for some order params
    function calcMinRate(
        address srcToken,
        address destToken,
        uint srcAmount,
        uint destAmount
    )
        internal
        view
        returns (uint minRate)
    {
        IPriceSource pricefeed = IPriceSource(getHub().priceSource());
        minRate = pricefeed.getOrderPriceInfo(
            srcToken,
            srcAmount,
            destAmount
        );
    }
}

interface IZeroExV3 {
    struct Order {
        address makerAddress;
        address takerAddress;
        address feeRecipientAddress;
        address senderAddress;
        uint256 makerAssetAmount;
        uint256 takerAssetAmount;
        uint256 makerFee;
        uint256 takerFee;
        uint256 expirationTimeSeconds;
        uint256 salt;
        bytes makerAssetData;
        bytes takerAssetData;
        bytes makerFeeAssetData;
        bytes takerFeeAssetData;
    }

    struct OrderInfo {
        uint8 orderStatus;
        bytes32 orderHash;
        uint256 orderTakerAssetFilledAmount;
    }

    struct FillResults {
        uint256 makerAssetFilledAmount;
        uint256 takerAssetFilledAmount;
        uint256 makerFeePaid;
        uint256 takerFeePaid;
        uint256 protocolFeePaid;
    }

    function cancelled(bytes32) external view returns (bool);
    function cancelOrder(Order calldata) external;
    function filled(bytes32) external view returns (uint256);
    function fillOrder(Order calldata, uint256, bytes calldata) external payable returns (FillResults memory);
    function getAssetProxy(bytes4) external view returns (address);
    function getOrderInfo(Order calldata) external view returns (OrderInfo memory);
    function isValidOrderSignature(Order calldata, bytes calldata) external view returns (bool);
    function preSign(bytes32) external;
    function protocolFeeCollector() external view returns (address);
    function protocolFeeMultiplier() external view returns (uint256);
}

interface IZeroExV2 {
    struct Order {
        address makerAddress;
        address takerAddress;
        address feeRecipientAddress;
        address senderAddress;
        uint256 makerAssetAmount;
        uint256 takerAssetAmount;
        uint256 makerFee;
        uint256 takerFee;
        uint256 expirationTimeSeconds;
        uint256 salt;
        bytes makerAssetData;
        bytes takerAssetData;
    }

    struct OrderInfo {
        uint8 orderStatus;
        bytes32 orderHash;
        uint256 orderTakerAssetFilledAmount;
    }

    struct FillResults {
        uint256 makerAssetFilledAmount;
        uint256 takerAssetFilledAmount;
        uint256 makerFeePaid;
        uint256 takerFeePaid;
    }

    function ZRX_ASSET_DATA() external view returns (bytes memory);
    function filled(bytes32) external view returns (uint256);
    function cancelled(bytes32) external view returns (bool);
    function getOrderInfo(Order calldata) external view returns (OrderInfo memory);
    function getAssetProxy(bytes4) external view returns (address);
    function isValidSignature(bytes32, address, bytes calldata) external view returns (bool);
    function preSign(bytes32, address, bytes calldata) external;
    function cancelOrder(Order calldata) external;
    function fillOrder(Order calldata, uint256, bytes calldata) external returns (FillResults memory);
}

/// @dev Minimal interface for our interactions with UniswapFactory
interface IUniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}

interface IUniswapExchange {
    // Trade ETH to ERC20
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient)
        external
        payable
        returns (uint256 tokens_bought);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline)
        external
        returns (uint256 eth_bought);
    // Trade ERC20 to ERC20
    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    )
        external
        returns (uint256 tokens_bought);

    /// @dev The following functions are only used in tests
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline)
        external
        payable
        returns (uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256 tokens_bought);
    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);
}

interface IOasisDex {
    function getFirstUnsortedOffer() external view returns(uint256);
    function getNextUnsortedOffer(uint256) external view returns(uint256);
    function getBestOffer(address, address) external view returns(uint256);
    function getOffer(uint256) external view returns (uint256, address, uint256, address);
    function getWorseOffer(uint256) external view returns(uint256);
    function isActive(uint256) external view returns (bool);
    function buy(uint256, uint256) external returns (bool);
    function cancel(uint256) external returns (bool);
    function offer(uint256, address, uint256, address) external returns (uint256);
}

interface IKyberNetworkProxy {
    function maxGasPrice() external view returns(uint256);
    function getUserCapInWei(address) external view returns(uint256);
    function getUserCapInTokenWei(address, address) external view returns(uint256);
    function enabled() external view returns(bool);
    function info(bytes32) external view returns(uint256);
    function swapEtherToToken(address, uint256) external payable returns(uint256);
    function swapTokenToEther(address, uint256, uint256) external returns(uint256);
    function swapTokenToToken(address, uint256, address, uint256) external returns(uint);
    function getExpectedRate(address, address, uint256) external view returns (uint256, uint256);
    function tradeWithHint(
        address, uint256, address, address, uint256, uint256, address, bytes calldata
    ) external payable returns(uint256);
}

interface IWrapperLock {
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256, uint8, bytes32, bytes32, uint256) external returns (bool);
    function deposit(uint256, uint256) external returns (bool);
}

/// @dev Minimal interface for our interactions with EthFinex WrapperLockEth
interface IWrapperLockEth {
    function balanceOf(address) external view returns (uint256);
    function deposit(uint256, uint256) external payable returns (bool);
}

/// @dev Minimal interface for our interactions with EthFinex WrapperRegistryEFX
interface IWrapperRegistryEFX {
    function token2WrapperLookup(address) external view returns (address);
    function wrapper2TokenLookup(address) external view returns (address);
}

contract ExchangeAdapter is DSMath {

    modifier onlyManager() {
        require(
            getManager() == msg.sender,
            "Manager must be sender"
        );
        _;
    }

    modifier notShutDown() {
        require(
            !hubShutDown(),
            "Hub must not be shut down"
        );
        _;
    }

    /// @dev Either manager sends, fund shut down, or order expired
    function ensureCancelPermitted(address _exchange, address _asset, bytes32 _id) internal {
        require(
            getManager() == msg.sender ||
            hubShutDown() ||
            getTrading().isOrderExpired(_exchange, _asset),
            "No cancellation condition met"
        );
        uint256 storedId;
        (storedId,,,,) = getTrading().exchangesToOpenMakeOrders(_exchange, _asset);
        require(
            uint256(_id) == storedId,
            "Passed identifier does not match that stored in Trading"
        );
    }

    function getTrading() internal view returns (Trading) {
        return Trading(payable(address(this)));
    }

    function getHub() internal view returns (Hub) {
        return Hub(getTrading().hub());
    }

    function getAccounting() internal view returns (Accounting) {
        return Accounting(getHub().accounting());
    }

    function hubShutDown() internal view returns (bool) {
        return getHub().isShutDown();
    }

    function getManager() internal view returns (address) {
        return getHub().manager();
    }

    function ensureNotInOpenMakeOrder(address _asset) internal view {
        require(
            !getTrading().isInOpenMakeOrder(_asset),
            "This asset is already in an open make order"
        );
    }

    function ensureCanMakeOrder(address _asset) internal view {
        require(
            block.timestamp >= getTrading().makerAssetCooldown(_asset),
            "Cooldown for the maker asset not reached"
        );
    }

    /// @notice Increment allowance of an asset for some target
    function approveAsset(
        address _asset,
        address _target,
        uint256 _amount,
        string memory _assetType
    )
        internal
    {
        Hub hub = getHub();
        Vault vault = Vault(hub.vault());

        require(
            IERC20(_asset).balanceOf(address(vault)) >= _amount,
            string(abi.encodePacked("Insufficient balance: ", _assetType))
        );

        vault.withdraw(_asset, _amount);
        uint256 allowance = IERC20(_asset).allowance(address(this), _target);
        require(
            IERC20(_asset).approve(_target, add(allowance, _amount)),
            string(abi.encodePacked("Approval failed: ", _assetType))
        );
    }

    /// @notice Reduce allowance of an asset for some target
    function revokeApproveAsset(
        address _asset,
        address _target,
        uint256 _amount,
        string memory _assetType
    )
        internal
    {
        uint256 allowance = IERC20(_asset).allowance(address(this), _target);
        uint256 newAllowance = (_amount > allowance) ? allowance : sub(allowance, _amount);
        require(
            IERC20(_asset).approve(_target, newAllowance),
            string(abi.encodePacked("Revoke approval failed: ", _assetType))
        );
    }

    /// @param orderAddresses [0] Order maker
    /// @param orderAddresses [1] Order taker
    /// @param orderAddresses [2] Order maker asset
    /// @param orderAddresses [3] Order taker asset
    /// @param orderAddresses [4] feeRecipientAddress
    /// @param orderAddresses [5] senderAddress
    /// @param orderAddresses [6] maker fee asset
    /// @param orderAddresses [7] taker fee asset
    /// @param orderValues [0] makerAssetAmount
    /// @param orderValues [1] takerAssetAmount
    /// @param orderValues [2] Maker fee
    /// @param orderValues [3] Taker fee
    /// @param orderValues [4] expirationTimeSeconds
    /// @param orderValues [5] Salt/nonce
    /// @param orderValues [6] Fill amount: amount of taker token to be traded
    /// @param orderValues [7] Dexy signature mode
    /// @param orderData [0] Encoded data specific to maker asset
    /// @param orderData [1] Encoded data specific to taker asset
    /// @param orderData [2] Encoded data specific to maker asset fee
    /// @param orderData [3] Encoded data specific to taker asset fee
    /// @param identifier Order identifier
    /// @param signature Signature of order maker

    // Responsibilities of makeOrder are:
    // - check sender
    // - check fund not shut down
    // - check price recent
    // - check risk management passes
    // - approve funds to be traded (if necessary)
    // - make order on the exchange
    // - check order was made (if possible)
    // - place asset in ownedAssets if not already tracked
    function makeOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public virtual { revert("Unimplemented"); }

    // Responsibilities of takeOrder are:
    // - check sender
    // - check fund not shut down
    // - check not buying own fund tokens
    // - check price exists for asset pair
    // - check price is recent
    // - check price passes risk management
    // - approve funds to be traded (if necessary)
    // - take order from the exchange
    // - check order was taken (if possible)
    // - place asset in ownedAssets if not already tracked
    function takeOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public virtual { revert("Unimplemented"); }

    // responsibilities of cancelOrder are:
    // - check sender is owner, or that order expired, or that fund shut down
    // - remove order from tracking array
    // - cancel order on exchange
    function cancelOrder(
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public virtual { revert("Unimplemented"); }

    // PUBLIC METHODS
    // PUBLIC VIEW METHODS
    /*
    @return {
        "makerAsset": "Maker asset",
        "takerAsset": "Taker asset",
        "makerQuantity": "Amount of maker asset"
        "takerQuantity": "Amount of taker asset"
    }
    */
    function getOrder(
        address onExchange,
        uint id,
        address makerAsset
    ) public view virtual returns (
        address,
        address,
        uint,
        uint
    ) { revert("Unimplemented"); }
}

contract EthfinexAdapter is DSMath, ExchangeAdapter {
    /// @param _orderAddresses [2] Order maker asset
    /// @param _orderAddresses [3] Order taker asset
    /// @param _orderData [0] Encoded data specific to maker asset
    /// @param _orderData [1] Encoded data specific to taker asset
    modifier orderAddressesMatchOrderData(
        address[8] memory _orderAddresses,
        bytes[4] memory _orderData
    )
    {
        require(
            getAssetAddress(_orderData[0]) == getWrapperToken(_orderAddresses[2]),
            "Maker asset data does not match order address in array"
        );
        require(
            getAssetAddress(_orderData[1]) == _orderAddresses[3],
            "Taker asset data does not match order address in array"
        );
        _;
    }

    //  METHODS

    //  PUBLIC METHODS

    /// @notice Make order by pre-approving signatures
    function makeOrder(
        address _targetExchange,
        address[8] memory _orderAddresses,
        uint[8] memory _orderValues,
        bytes[4] memory _orderData,
        bytes32 _identifier,
        bytes memory _signature
    )
        public
        override
        onlyManager
        notShutDown
        orderAddressesMatchOrderData(_orderAddresses, _orderData)
    {
        ensureCanMakeOrder(_orderAddresses[2]);

        IZeroExV2.Order memory order = constructOrderStruct(_orderAddresses, _orderValues, _orderData);
        bytes memory wrappedMakerAssetData = _orderData[0];
        bytes memory takerAssetData = _orderData[1];
        address makerAsset = _orderAddresses[2];
        address takerAsset = getAssetAddress(takerAssetData);

        // Order parameter checks
        getTrading().updateAndGetQuantityBeingTraded(makerAsset);
        ensureNotInOpenMakeOrder(makerAsset);

        wrapMakerAsset(_targetExchange, makerAsset, wrappedMakerAssetData, order.makerAssetAmount, order.expirationTimeSeconds);

        IZeroExV2.OrderInfo memory orderInfo = IZeroExV2(_targetExchange).getOrderInfo(order);
        IZeroExV2(_targetExchange).preSign(orderInfo.orderHash, address(this), _signature);

        require(
            IZeroExV2(_targetExchange).isValidSignature(
                orderInfo.orderHash,
                address(this),
                _signature
            ),
            "INVALID_ORDER_SIGNATURE"
        );

        updateStateMakeOrder(_targetExchange, order);
    }

    /// @notice Cancel the 0x make order
    function cancelOrder(
        address _targetExchange,
        address[8] memory _orderAddresses,
        uint[8] memory _orderValues,
        bytes[4] memory _orderData,
        bytes32 _identifier,
        bytes memory _signature
    )
        public
        override
        orderAddressesMatchOrderData(_orderAddresses, _orderData)
    {
        IZeroExV2.Order memory order = getTrading().getZeroExV2OrderDetails(_identifier);
        ensureCancelPermitted(_targetExchange, _orderAddresses[2], _identifier);
        IZeroExV2(_targetExchange).cancelOrder(order);

        updateStateCancelOrder(_targetExchange, order);
    }

    /// @notice Unwrap (withdraw) tokens, uses _orderAddresses for input list of tokens to be unwrapped
    /// @dev Call to "withdraw" fails if timestamp < `Wrapper.depositLock(tradingComponent)`
    function withdrawTokens(
        address _targetExchange,
        address[8] memory _orderAddresses,
        uint[8] memory _orderValues,
        bytes[4] memory _orderData,
        bytes32 _identifier,
        bytes memory _signature
    )
        public
    {
        Hub hub = getHub();
        address nativeAsset = Accounting(hub.accounting()).NATIVE_ASSET();

        for (uint i = 0; i < _orderAddresses.length; i++) {
            if (_orderAddresses[i] == address(0)) continue;
            address wrappedToken = getWrapperToken(_orderAddresses[i]);
            uint balance = IWrapperLock(wrappedToken).balanceOf(address(this));
            require(balance > 0, "Insufficient balance");
            IWrapperLock(wrappedToken).withdraw(balance, 0, bytes32(0), bytes32(0), 0);
            if (_orderAddresses[i] == nativeAsset) {
                WETH(payable(nativeAsset)).deposit.value(balance)();
            }
            getTrading().removeOpenMakeOrder(_targetExchange, _orderAddresses[i]);
            getTrading().returnAssetToVault(_orderAddresses[i]);
        }
    }

     /// @notice Minor: Wrapped tokens directly sent to the fund are not accounted. To be called by Trading spoke
    function getOrder(address _targetExchange, uint256 _id, address _makerAsset)
        public
        view
        override
        returns (address, address, uint256, uint256)
    {
        uint orderId;
        uint orderIndex;
        address takerAsset;
        uint makerQuantity;
        uint takerQuantity;
        (orderId, , orderIndex) = Trading(msg.sender).getOpenOrderInfo(_targetExchange, _makerAsset);
        (, takerAsset, makerQuantity, takerQuantity) = Trading(msg.sender).getOrderDetails(orderIndex);

        // Check if order has been completely filled
        uint takerAssetFilledAmount = IZeroExV2(_targetExchange).filled(bytes32(orderId));
        if (sub(takerQuantity, takerAssetFilledAmount) == 0) {
            return (_makerAsset, takerAsset, 0, 0);
        }

        // Check if tokens have been withdrawn (cancelled order may still need to be accounted if there is balance)
        uint balance = IWrapperLock(getWrapperTokenFromAdapterContext(_makerAsset)).balanceOf(msg.sender);
        if (balance == 0) {
            return (_makerAsset, takerAsset, 0, 0);
        }
        return (_makerAsset, takerAsset, makerQuantity, sub(takerQuantity, takerAssetFilledAmount));
    }

    // INTERNAL METHODS

    /// @notice needed to avoid stack too deep error
    /// @dev deposit time should be greater than 1 hour
    function wrapMakerAsset(
        address _targetExchange,
        address _makerAsset,
        bytes memory _wrappedMakerAssetData,
        uint _makerQuantity,
        uint _orderExpirationTime
    )
        internal
    {
        Hub hub = getHub();

        // Deposit to rounded up value of time difference of expiration time and current time (in hours)
        uint depositTime = (
            sub(_orderExpirationTime, block.timestamp) / 1 hours
        ) + 1;

        address nativeAsset = Accounting(hub.accounting()).NATIVE_ASSET();
        address wrappedToken = getWrapperToken(_makerAsset);
        // Handle case for WETH vs ERC20
        if (_makerAsset == nativeAsset) {
            Vault vault = Vault(hub.vault());
            vault.withdraw(_makerAsset, _makerQuantity);
            WETH(payable(nativeAsset)).withdraw(_makerQuantity);
            IWrapperLockEth(wrappedToken).deposit.value(_makerQuantity)(_makerQuantity, depositTime);
        } else {
            approveAsset(
                _makerAsset,
                wrappedToken,
                _makerQuantity,
                "makerAsset"
            );
            IWrapperLock(wrappedToken).deposit(_makerQuantity, depositTime);
        }
    }

    // @dev avoids stack too deep error
    function updateStateCancelOrder(address _targetExchange, IZeroExV2.Order memory _order)
        internal
    {
        // Order is not removed from OpenMakeOrder mapping as it's needed for accounting (wrapped tokens)
        getAccounting().updateOwnedAssets();
        getTrading().orderUpdateHook(
            _targetExchange,
            IZeroExV2(_targetExchange).getOrderInfo(_order).orderHash,
            Trading.UpdateType.cancel,
            [address(0), address(0)],
            [uint(0), uint(0), uint(0)]
        );
    }

    // @dev avoids stack too deep error
    function updateStateMakeOrder(address _targetExchange, IZeroExV2.Order memory _order)
        internal
    {
        address wrapperRegistry = Registry(getTrading().registry()).ethfinexWrapperRegistry();
        address wrappedMakerAsset = getAssetAddress(_order.makerAssetData);
        address makerAsset = IWrapperRegistryEFX(
            wrapperRegistry
        ).wrapper2TokenLookup(wrappedMakerAsset);
        address takerAsset = getAssetAddress(_order.takerAssetData);
        IZeroExV2.OrderInfo memory orderInfo = IZeroExV2(_targetExchange).getOrderInfo(_order);

        getAccounting().addAssetToOwnedAssets(takerAsset);
        getTrading().orderUpdateHook(
            _targetExchange,
            orderInfo.orderHash,
            Trading.UpdateType.make,
            [payable(makerAsset), payable(takerAsset)],
            [_order.makerAssetAmount, _order.takerAssetAmount, uint(0)]
        );
        getTrading().addOpenMakeOrder(
            _targetExchange,
            makerAsset,
            takerAsset,
            address(0),
            uint256(orderInfo.orderHash),
            _order.expirationTimeSeconds
        );
        getTrading().addZeroExV2OrderData(orderInfo.orderHash, _order);
    }

    // VIEW METHODS

    function constructOrderStruct(
        address[8] memory _orderAddresses,
        uint[8] memory _orderValues,
        bytes[4] memory _orderData
    )
        internal
        view
        returns (IZeroExV2.Order memory _order)
    {
        _order = IZeroExV2.Order({
            makerAddress: _orderAddresses[0],
            takerAddress: _orderAddresses[1],
            feeRecipientAddress: _orderAddresses[4],
            senderAddress: _orderAddresses[5],
            makerAssetAmount: _orderValues[0],
            takerAssetAmount: _orderValues[1],
            makerFee: _orderValues[2],
            takerFee: _orderValues[3],
            expirationTimeSeconds: _orderValues[4],
            salt: _orderValues[5],
            makerAssetData: _orderData[0],
            takerAssetData: _orderData[1]
        });
    }

    function getAssetProxy(address _targetExchange, bytes memory _assetData)
        internal
        view
        returns (address assetProxy_)
    {
        bytes4 assetProxyId;
        assembly {
            assetProxyId := and(mload(
                add(_assetData, 32)),
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }
        assetProxy_ = IZeroExV2(_targetExchange).getAssetProxy(assetProxyId);
    }

    function getAssetAddress(bytes memory _assetData)
        internal
        view
        returns (address assetAddress_)
    {
        assembly {
            assetAddress_ := mload(add(_assetData, 36))
        }
    }

    /// @dev Function to be called from Trading spoke context (Delegate call)
    function getWrapperToken(address _token)
        internal
        view
        returns (address)
    {
        address wrapperRegistry = Registry(getTrading().registry()).ethfinexWrapperRegistry();
        return IWrapperRegistryEFX(wrapperRegistry).token2WrapperLookup(_token);
    }

    /// @dev Function to be called by Trading spoke without change of context (Non delegate call)
    function getWrapperTokenFromAdapterContext(address _token)
        internal
        view
        returns (address)
    {
        address wrapperRegistry = Registry(Trading(msg.sender).registry()).ethfinexWrapperRegistry();
        return IWrapperRegistryEFX(wrapperRegistry).token2WrapperLookup(_token);
    }
}

contract EngineAdapter is DSMath, TokenUser, ExchangeAdapter {

    /// @notice Buys Ether from the engine, selling MLN
    /// @param targetExchange Address of the engine
    /// @param orderValues [0] Min Eth to receive from the engine
    /// @param orderValues [1] MLN quantity
    /// @param orderValues [6] Same as orderValues[1]
    /// @param orderAddresses [2] WETH token
    /// @param orderAddresses [3] MLN token
    function takeOrder (
        address targetExchange,
        address[8] memory orderAddresses,
        uint[8] memory orderValues,
        bytes[4] memory orderData,
        bytes32 identifier,
        bytes memory signature
    ) public override onlyManager notShutDown {
        Hub hub = getHub();

        address wethAddress = orderAddresses[2];
        address mlnAddress = orderAddresses[3];
        uint minEthToReceive = orderValues[0];
        uint mlnQuantity = orderValues[1];

        require(
            wethAddress == Registry(hub.registry()).nativeAsset(),
            "maker asset doesnt match nativeAsset on registry"
        );
        require(
            orderValues[1] == orderValues[6],
            "fillTakerQuantity must equal takerAssetQuantity"
        );

        approveAsset(mlnAddress, targetExchange, mlnQuantity, "takerAsset");

        uint ethToReceive = Engine(targetExchange).ethPayoutForMlnAmount(mlnQuantity);

        require(
            ethToReceive >= minEthToReceive,
            "Expected ETH to receive is less than takerQuantity (minEthToReceive)"
        );

        Engine(targetExchange).sellAndBurnMln(mlnQuantity);
        WETH(payable(wethAddress)).deposit.value(ethToReceive)();
        safeTransfer(wethAddress, address(Vault(hub.vault())), ethToReceive);

        getAccounting().addAssetToOwnedAssets(wethAddress);
        getAccounting().updateOwnedAssets();
        getTrading().orderUpdateHook(
            targetExchange,
            bytes32(0),
            Trading.UpdateType.take,
            [payable(wethAddress), payable(mlnAddress)],
            [ethToReceive, mlnQuantity, mlnQuantity]
        );
    }
}

interface IEngine {
    function payAmguInEther() external payable;
    function getAmguPrice() external view returns (uint256);
}

contract Engine is DSMath {

    event RegistryChange(address registry);
    event SetAmguPrice(uint amguPrice);
    event AmguPaid(uint amount);
    event Thaw(uint amount);
    event Burn(uint amount);

    uint public constant MLN_DECIMALS = 18;

    Registry public registry;
    uint public amguPrice;
    uint public frozenEther;
    uint public liquidEther;
    uint public lastThaw;
    uint public thawingDelay;
    uint public totalEtherConsumed;
    uint public totalAmguConsumed;
    uint public totalMlnBurned;

    constructor(uint _delay, address _registry) public {
        lastThaw = block.timestamp;
        thawingDelay = _delay;
        _setRegistry(_registry);
    }

    modifier onlyMGM() {
        require(
            msg.sender == registry.MGM(),
            "Only MGM can call this"
        );
        _;
    }

    /// @dev Registry owner is MTC
    modifier onlyMTC() {
        require(
            msg.sender == registry.owner(),
            "Only MTC can call this"
        );
        _;
    }

    function _setRegistry(address _registry) internal {
        registry = Registry(_registry);
        emit RegistryChange(address(registry));
    }

    /// @dev only callable by MTC
    function setRegistry(address _registry)
        external
        onlyMTC
    {
        _setRegistry(_registry);
    }

    /// @dev set price of AMGU in MLN (base units)
    /// @dev only callable by MGM
    function setAmguPrice(uint _price)
        external
        onlyMGM
    {
        amguPrice = _price;
        emit SetAmguPrice(_price);
    }

    function getAmguPrice() public view returns (uint) { return amguPrice; }

    function premiumPercent() public view returns (uint) {
        if (liquidEther < 1 ether) {
            return 0;
        } else if (liquidEther >= 1 ether && liquidEther < 5 ether) {
            return 5;
        } else if (liquidEther >= 5 ether && liquidEther < 10 ether) {
            return 10;
        } else if (liquidEther >= 10 ether) {
            return 15;
        }
    }

    function payAmguInEther() external payable {
        require(
            registry.isFundFactory(msg.sender) ||
            registry.isFund(msg.sender),
            "Sender must be a fund or the factory"
        );
        uint mlnPerAmgu = getAmguPrice();
        uint ethPerMln;
        (ethPerMln,) = priceSource().getPrice(address(mlnToken()));
        uint amguConsumed;
        if (mlnPerAmgu > 0 && ethPerMln > 0) {
            amguConsumed = (mul(msg.value, 10 ** uint(MLN_DECIMALS))) / (mul(ethPerMln, mlnPerAmgu));
        } else {
            amguConsumed = 0;
        }
        totalEtherConsumed = add(totalEtherConsumed, msg.value);
        totalAmguConsumed = add(totalAmguConsumed, amguConsumed);
        frozenEther = add(frozenEther, msg.value);
        emit AmguPaid(amguConsumed);
    }

    /// @notice Move frozen ether to liquid pool after delay
    /// @dev Delay only restarts when this function is called
    function thaw() external {
        require(
            block.timestamp >= add(lastThaw, thawingDelay),
            "Thawing delay has not passed"
        );
        require(frozenEther > 0, "No frozen ether to thaw");
        lastThaw = block.timestamp;
        liquidEther = add(liquidEther, frozenEther);
        emit Thaw(frozenEther);
        frozenEther = 0;
    }

    /// @return ETH per MLN including premium
    function enginePrice() public view returns (uint) {
        uint ethPerMln;
        (ethPerMln, ) = priceSource().getPrice(address(mlnToken()));
        uint premium = (mul(ethPerMln, premiumPercent()) / 100);
        return add(ethPerMln, premium);
    }

    function ethPayoutForMlnAmount(uint mlnAmount) public view returns (uint) {
        return mul(mlnAmount, enginePrice()) / 10 ** uint(MLN_DECIMALS);
    }

    /// @notice MLN must be approved first
    function sellAndBurnMln(uint mlnAmount) external {
        require(registry.isFund(msg.sender), "Only funds can use the engine");
        require(
            mlnToken().transferFrom(msg.sender, address(this), mlnAmount),
            "MLN transferFrom failed"
        );
        uint ethToSend = ethPayoutForMlnAmount(mlnAmount);
        require(ethToSend > 0, "No ether to pay out");
        require(liquidEther >= ethToSend, "Not enough liquid ether to send");
        liquidEther = sub(liquidEther, ethToSend);
        totalMlnBurned = add(totalMlnBurned, mlnAmount);
        msg.sender.transfer(ethToSend);
        mlnToken().burn(mlnAmount);
        emit Burn(mlnAmount);
    }

    /// @dev Get MLN from the registry
    function mlnToken()
        public
        view
        returns (BurnableToken)
    {
        return BurnableToken(registry.mlnToken());
    }

    /// @dev Get PriceSource from the registry
    function priceSource()
        public
        view
        returns (IPriceSource)
    {
        return IPriceSource(registry.priceSource());
    }
}

abstract contract AmguConsumer is DSMath {

    /// @dev each of these must be implemented by the inheriting contract
    function engine() public view virtual returns (address);
    function mlnToken() public view virtual returns (address);
    function priceSource() public view virtual returns (address);
    function registry() public view virtual returns (address);
    event AmguPaid(address indexed payer, uint256 totalAmguPaidInEth, uint256 amguChargableGas, uint256 incentivePaid);

    /// bool deductIncentive is used when sending extra eth beyond amgu
    modifier amguPayable(bool deductIncentive) {
        uint preGas = gasleft();
        _;
        uint postGas = gasleft();

        uint mlnPerAmgu = IEngine(engine()).getAmguPrice();
        uint mlnQuantity = mul(
            mlnPerAmgu,
            sub(preGas, postGas)
        );
        address nativeAsset = Registry(registry()).nativeAsset();
        uint ethToPay = IPriceSource(priceSource()).convertQuantity(
            mlnQuantity,
            mlnToken(),
            nativeAsset
        );
        uint incentiveAmount;
        if (deductIncentive) {
            incentiveAmount = Registry(registry()).incentive();
        } else {
            incentiveAmount = 0;
        }
        require(
            msg.value >= add(ethToPay, incentiveAmount),
            "Insufficent AMGU and/or incentive"
        );
        IEngine(engine()).payAmguInEther.value(ethToPay)();

        require(
            msg.sender.send(
                sub(
                    sub(msg.value, ethToPay),
                    incentiveAmount
                )
            ),
            "Refund failed"
        );
        emit AmguPaid(msg.sender, ethToPay, sub(preGas, postGas), incentiveAmount);
    }
}

contract WETH {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    receive() external payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

contract TokenUser is DSMath {
    function safeTransfer(
        address _token,
        address _to,
        uint _value
    ) internal {
        uint receiverPreBalance = IERC20(_token).balanceOf(_to);
        IERC20(_token).transfer(_to, _value);
        uint receiverPostBalance = IERC20(_token).balanceOf(_to);
        require(
            add(receiverPreBalance, _value) == receiverPostBalance,
            "Receiver did not receive tokens in transfer"
        );
    }

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint _value
    ) internal {
        uint receiverPreBalance = IERC20(_token).balanceOf(_to);
        IERC20(_token).transferFrom(_from, _to, _value);
        uint receiverPostBalance = IERC20(_token).balanceOf(_to);
        require(
            add(receiverPreBalance, _value) == receiverPostBalance,
            "Receiver did not receive tokens in transferFrom"
        );
    }
}

contract StandardToken is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
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
        override
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public virtual override returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
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
    function approve(address _spender, uint256 _value) public virtual override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

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
        virtual
        override
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
        emit Transfer(_from, _to, _value);
        return true;
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
        virtual
        returns (bool)
    {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
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
        virtual
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

    /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param _account The account that will receive the created tokens.
    * @param _amount The amount that will be created.
     */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param _account The account whose tokens will be burnt.
     * @param _amount The amount that will be burnt.
     */
    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0));
        require(_amount <= balances[_account]);

        totalSupply_ = totalSupply_.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal _burn function.
     * @param _account The account whose tokens will be burnt.
     * @param _amount The amount that will be burnt.
     */
    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= allowed[_account][msg.sender]);
        allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
        emit Approval(_account, msg.sender, allowed[_account][msg.sender]);
        _burn(_account, _amount);
    }
}

contract PreminedToken is StandardToken {
    string public symbol;
    string public  name;
    uint8 public decimals;

    constructor(string memory _symbol, uint8 _decimals, string memory _name) public {
        symbol = _symbol;
        decimals = _decimals;
        name = _name;
        totalSupply_ = 1000000 * 10**uint(decimals);
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _who) external view returns (uint256);

  function allowance(address _owner, address _spender)
    external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function approve(address _spender, uint256 _value) external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/// @dev Just adds extra functions that we use elsewhere
abstract contract ERC20WithFields is IERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
}

contract BurnableToken is PreminedToken {
    constructor(string memory _symbol, uint8 _decimals, string memory _name)
        public
        PreminedToken(_symbol, _decimals, _name)
    {}

    function burn(uint _amount) public {
        _burn(msg.sender, _amount);
    }

    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract DSGuardEvents {
    event LogPermit(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );

    event LogForbid(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );
}

contract DSGuard is DSAuth, DSAuthority, DSGuardEvents {
    bytes32 constant public ANY = bytes32(uint(-1));

    mapping (bytes32 => mapping (bytes32 => mapping (bytes32 => bool))) acl;

    function canCall(
        address src_, address dst_, bytes4 sig
    ) public view override returns (bool) {
        bytes32 src = bytes32(bytes20(src_));
        bytes32 dst = bytes32(bytes20(dst_));

        return acl[src][dst][sig]
            || acl[src][dst][ANY]
            || acl[src][ANY][sig]
            || acl[src][ANY][ANY]
            || acl[ANY][dst][sig]
            || acl[ANY][dst][ANY]
            || acl[ANY][ANY][sig]
            || acl[ANY][ANY][ANY];
    }

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public auth {
        acl[src][dst][sig] = true;
        emit LogPermit(src, dst, sig);
    }

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public auth {
        acl[src][dst][sig] = false;
        emit LogForbid(src, dst, sig);
    }

    function permit(address src, address dst, bytes32 sig) public {
        permit(bytes32(bytes20(src)), bytes32(bytes20(dst)), sig);
    }
    function forbid(address src, address dst, bytes32 sig) public {
        forbid(bytes32(bytes20(src)), bytes32(bytes20(dst)), sig);
    }

}

contract DSGuardFactory {
    mapping (address => bool)  public  isGuard;

    function newGuard() public returns (DSGuard guard) {
        guard = new DSGuard();
        guard.setOwner(msg.sender);
        isGuard[address(guard)] = true;
    }
}

abstract contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view virtual returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

/// @notice Controlled by governance
contract Version is FundFactory, DSAuth {

    constructor(
        address _accountingFactory,
        address _feeManagerFactory,
        address _participationFactory,
        address _sharesFactory,
        address _tradingFactory,
        address _vaultFactory,
        address _policyManagerFactory,
        address _registry,
        address _postDeployOwner
    )
        public
        FundFactory(
            _accountingFactory,
            _feeManagerFactory,
            _participationFactory,
            _sharesFactory,
            _tradingFactory,
            _vaultFactory,
            _policyManagerFactory,
            address(this)
        )
    {
        associatedRegistry = Registry(_registry);
        setOwner(_postDeployOwner);
    }

    function shutDownFund(address _hub) external {
        require(
            managersToHubs[msg.sender] == _hub,
            "Conditions not met for fund shutdown"
        );
        Hub(_hub).shutDownFund();
    }
}