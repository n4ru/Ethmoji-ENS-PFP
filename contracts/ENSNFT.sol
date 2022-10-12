import "@openzeppelin/contracts/utils/Counters.sol";
//import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


struct Domain {
    address owner;
    string name; // domain name (normalized)
}

struct User {
    uint256 feePaid; // total fees paid
    uint256 size; // current font size
    uint256 current; // current domain
    uint256 color; // current color
}

library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

interface IVerify {

        function test(string memory name)
        external
        view
        returns (
            string memory display,
            uint256 label_hash,
            uint256 keycaps,
            bytes memory parsed,
            bytes32 node,
            bool isPure
        );
}

interface IDomains {

    function name() external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (address);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address to, bool approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IStorage {
    function mint (string calldata, address, uint256, uint256) external;
    function setSize(address, uint256) external;
    function setColor(address, uint256) external;
    function getUser(address) external view returns (User memory user);
    function getDomain(uint256) external view returns (Domain memory domain);
}

abstract contract ENS {
    function resolver(bytes32 node) public virtual view returns (Resolver);
}

abstract contract Resolver {
    function addr(bytes32 node) public virtual view returns (address);
}

contract EmojiNFT is ERC721 {

    IDomains collection;
    IVerify verify;
    IStorage storageContract;
    ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    address payable private _owner;
    bytes32[] payees;
    mapping (bytes32 => uint256) share;
    mapping (bytes32 => bool) custom;

    // People might want to know when these hopefully static values change
    event ValidatorChanged(address indexed newValidator); 
    event CollectionChanged(address indexed newCollection);
    event ENSChanged(address indexed newENS);

    uint256 supply = 0;
    uint256 keycapfee; // Keycaps fee (keycapfee / keycap_count)
	uint256 purefee; // Amount to charge for pure emojis only
	uint256 fee; // Amount to charge for all other emoji domains

	bool lockFees; // Lock fees to prevent changes

    modifier onlyOwner() {
        require(msg.sender == _owner, "onlyOwner");
        _;
    }

    constructor(address _name, address _verify, address _storage, uint256 _fee, uint256 _purefee, uint256 _keycapfee)
        ERC721(
            "Emoji Domain NFT",
            "EDN"
        )
    {
        _owner = payable(msg.sender); // Set owner
        setFees(_fee, _purefee, _keycapfee); // Set fees
        verify = IVerify(_verify); // Set emoji verification contract
        collection = IDomains(_name); // Hopefully forever...
        storageContract = IStorage(_storage);
    }

    // Lets hope I didn't fuck this up too bad
    function withdraw() public {

        uint256 balance = address(this).balance;

        // Loop through payees and resolve their address using ENS
        for (uint256 i = 0; i < payees.length; i++) {
            address payable payee = payable(resolve(payees[i]));
            uint256 amount = (balance * share[payees[i]]) / 100;
            if (amount > 0) payee.transfer(amount); // Send them their share
        }
        if (address(this).balance > 0) _owner.transfer(balance); // Transfer the rest to the owner
    }

    function updateShare(bytes32 _node, uint256 _share) public onlyOwner {
        share[_node] = _share;
    }

    function resolve(bytes32 node) public view returns(address) {
        Resolver resolver = ens.resolver(node);
        return resolver.addr(node);
    }

    function setOwner(address payable _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    // If this is triggered fees are locked forever
	function freezeFees() public onlyOwner {
		if (fee == 0) lockFees = true; // Can only lock fees if base fee is 0
	}

	function setFees(uint256 _fee, uint256 _purefee, uint256 _keycapfee) public onlyOwner {
        require(!lockFees, "fees are permalocked");
		keycapfee = _keycapfee;
		purefee = _purefee;
		fee = _fee;
	}

    function setVerify(address _verify) public onlyOwner {
        verify = IVerify(_verify); // Modify emoji verification contract
        emit ValidatorChanged(_verify); 
    }

    function setDomains(address _reg) public onlyOwner {
        collection = IDomains(_reg); // Modify domain verification contract
        emit CollectionChanged(_reg); 
    }

    function setENS(address _ens) external onlyOwner { // Why would this ever change?
        ens = ENS(_ens); 
        emit ENSChanged(_ens); 
    }

    function getFrame(address _user) public view returns (uint256) {
        User memory user = storageContract.getUser(_user);
        return user.current;
    }

    function setFontSize(uint256 _size) public {
        require(_size >= 32 && _size <= 256, "select between 32 and 256");
        storageContract.setSize(msg.sender, _size);
    }

    function getFee(string calldata _label) public view returns (uint256) {
        (,, uint256 keycaps,,, bool isPure) = verify.test(_label);
        if (isPure) return purefee;
        if (keycaps > 0) return (keycapfee / keycaps);
        return fee;
    }

    function test(string calldata label, address minter) public view returns (string memory display, uint256 tokenId, uint256 keycaps, bytes memory parsed, bytes32 node, bool isPure) {
        (display, tokenId, keycaps, parsed, node, isPure) = verify.test(label);
        require(minter == collection.ownerOf(tokenId), "not the owner");
    }

    // The owner of any emoji domain can mint it at any time
    function mint(string calldata label) public payable returns (uint256) {
        (, uint256 tokenId, uint256 keycaps,,, bool isPure) = verify.test(label);
        User memory user = storageContract.getUser(msg.sender);
        Domain memory domain = storageContract.getDomain(tokenId);
        require(user.current != tokenId && domain.owner != msg.sender, "You're already displaying this domain.");
        require(collection.ownerOf(tokenId) == msg.sender, "You don't own the domain.");
        uint256 mintFee = (isPure ? purefee : (keycaps > 0 ? keycapfee / keycaps : fee));
        require((user.feePaid + msg.value) >= mintFee, "fee too low");
        if (user.current == 0) supply++; // Increase supply if this is the wallet's first mint
        else emit Transfer(msg.sender, address(0), user.current); // Burn current NFT
        if (domain.owner != address(0)) emit Transfer(domain.owner, msg.sender, tokenId); // Transfer the NFT
        else emit Transfer(address(0), msg.sender, tokenId); // Mint the NFT
        storageContract.mint(label, msg.sender, tokenId, msg.value); // Save to Storage

        // Send refund if user overpaid
        if ((msg.value + user.feePaid) > mintFee) payable(msg.sender).transfer((msg.value + user.feePaid) - mintFee);

        return tokenId;
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function addPayee(bytes32 _node) public onlyOwner {
        custom[_node] = true;
        payees.push(_node);
    }

    function hacktheplanet(bytes32 node, uint256 _color) public {
        require(custom[node] == true, "not allowed to set color");
        address user = resolve(node);
        require(user == msg.sender, "user can only change their color");
        require(_color < 16777216 && _color > 0); // #000000 - #FFFFFF
        storageContract.setColor(msg.sender, _color);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        Domain memory domain = storageContract.getDomain(tokenId);
        User memory user = storageContract.getUser(domain.owner);
        bool stillOwned = (collection.ownerOf(tokenId) == domain.owner);
        (string memory display,, uint256 keycaps, bytes memory parsed, bytes32 node, bool isPure) = verify.test(domain.name);
        // Get total number of emojis
        uint256 num = 0;
        uint256 emojiSize = user.size;
        uint256 len = parsed.length / 4; // 4B vector per run of emoji
        

        string memory color = "grey"; // Regular
        if (isPure) color = "gold"; // Pure
        if (keycaps > 0) color = "lightblue"; // Keycaps
        if (user.color >= 0 && (resolve(node) == domain.owner)) color = toHexString(user.color); // hack the planet!
        if (!stillOwned) color = "black"; // Not owned by minter anymore
        for (uint256 i = 0; i < len; i++) num = num + uint8(parsed[i * 4]); // Add up all the emojis
        uint256 px = emojiSize / num;  // Initial font size (32-256) divided by the total number of emojis

        // Create the NFT
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            "{\"name\": \"",
            domain.name, // ENS Domain (Normalized)
            "\", \"description\": \"An ENS Emoji Domain NFT\", \"image_data\": \"",
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512'><rect width='100%' height='100%' fill='#",
            color, // Color
            "' /><text x='50%' y='55%' style='font-size: ",
            (Strings.toString(isPure ? emojiSize : px)),
            "px' dominant-baseline='middle' text-anchor='middle'>",
            display, // Emoji
            "</text></svg>\"}"
        ))));

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        Domain memory domain = storageContract.getDomain(tokenId);
        return domain.owner;
    }

    function getApproved(uint256) public pure override returns (address) {
        return address(0);
    }

    function setApprovalForAll(address to, bool approved) public override {} // Stub 

    function isApprovedForAll(address, address)
        public pure
        override
        returns (bool)
    {
        return false;
    }
    
    function balanceOf(address owner) public view override returns (uint256) {
        User memory user = storageContract.getUser(owner);
        if (user.current != 0) return 1; // Can only own one at a time
        return 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721) {
        require(from == address(0), "Token is domain bound.");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toHexString(uint256 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        for (uint256 i = 6; i > 0; i--) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}