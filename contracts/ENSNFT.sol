import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface Verify {
    function test(string memory name) external view returns (string memory display,
            uint256 label_hash,
            bytes memory parsed,
            bytes32 node,
            bool isPure);
}

interface Domains {

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

contract ENS is ERC721 {

    Domains collection;
    Verify verify;

    address payable private _owner;
    mapping (address => bool) isPaid;
	mapping (address => uint256) minted;
    mapping (address => uint256) size;
    mapping (uint256 => string) names;
    mapping (uint256 => address) tokenOwners;

    uint256 supply = 0;
	uint256 purefee = 0 ether; // Amount to charge for pure emojis only
	uint256 fee = 0 ether; // Amount to charge for all other emoji domains
    
	bool lockFees;

    modifier onlyOwner() {
        require(msg.sender == _owner, "onlyOwner");
        _;
    }

    constructor(address _name, address _verify, uint256 _fee, uint256 _purefee)
        ERC721(
            "Emoji ENS PFP",
            "EENS"
        )
    {
        _owner = payable(msg.sender); // Set owner
        setFees(_fee, _purefee); // Set fees
        verify = Verify((_verify)); // Set emoji verification contract
        collection = Domains(address(_name)); // Hopefully forever...
    }

    // If this is triggered fees are locked forever (and normal fee is 0)
	function freezeFees() public onlyOwner {
		if (fee == 0) lockFees = true;
	}

	function setFees(uint256 _fee, uint256 _purefee) public onlyOwner {
        require(!lockFees, "fees are permalocked");
		purefee = _purefee;
		fee = _fee;
	}

    function setVerify(address _verify) public onlyOwner {
        verify = Verify(_verify); // Modify emoji verification contract
    }

    function sweep() public onlyOwner {
        _owner.transfer(address(this).balance);
    }

    function getFrame(address user) public view returns (uint256) { 
        return minted[user];
    }

    function setFontSize(uint256 _size) public {
        require(_size >= 32 && _size <= 256, "select between 32 and 256");
        size[msg.sender] = _size;
    }

    function test(string calldata label, address minter) public view returns (string memory display, uint256 tokenId, bytes memory parsed, bytes32 node, bool isPure) {
        (display, tokenId, parsed, node, isPure) = verify.test(label);
        require(minter == collection.ownerOf(tokenId), "not the owner");
    }

    // The owner of any emoji domain can mint it at any time
    function mint(string calldata label) public payable returns (uint256) {
        (string memory display, uint256 tokenId, bytes memory parsed, bytes32 node, bool isPure)  = verify.test(label);
        require(minted[msg.sender] != tokenId, "You're already displaying this domain'.");
        require(collection.ownerOf(tokenId) == msg.sender, "You don't own the domain.");
		if (isPure && !isPaid[msg.sender]) {
            require(msg.value >= purefee, "pure fee");
            isPaid[msg.sender] = true;
        }
        if (minted[msg.sender] == 0) supply++; // Increase supply if this is the wallet's first mint
        if (minted[msg.sender] != 0) {
            tokenOwners[minted[msg.sender]] = address(0); // Set previous domain owner to null address
            emit Transfer(msg.sender, address(0), minted[msg.sender]); // Burn current NFT
        }
        if (tokenOwners[tokenId] != msg.sender && tokenOwners[tokenId] != address(0)) 
            emit Transfer(tokenOwners[tokenId], msg.sender, tokenId); // Transfer the NFT
        else 
            emit Transfer(address(0), msg.sender, tokenId); // Mint the NFT
        minted[msg.sender] = tokenId; // Save owner -> token map
        tokenOwners[tokenId] = msg.sender; // Save token -> owner map
        if (keccak256(abi.encodePacked(names[tokenId])) == keccak256(abi.encodePacked("")))
            names[tokenId] = label; // Save token -> label map
        return tokenId;
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bool stillOwned = (collection.ownerOf(tokenId) == tokenOwners[tokenId]);
        stillOwned = stillOwned && tokenOwners[tokenId] != address(0);
        //require(stillOwned, "was not minted by current owner");
        //require(tokenOwners[tokenId] != address(0), "not owned by anyone");
        string memory label = names[tokenId];
        (string memory display, uint256 token, bytes memory parsed, bytes32 node, bool isPure)  = verify.test(label);
        // Get total number of emojis
        uint256 num = 0;
        uint256 emojiSize = (size[tokenOwners[tokenId]] == 0 ? 256 : size[tokenOwners[tokenId]]);
        uint256 len = parsed.length / 4; 
        for (uint256 i = 0; i < len; i++) num = num + uint8(parsed[i * 4]);
        uint256 px = emojiSize / num; 
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            "{\"name\": \"", 
            display, // ENS Domain (Beautified)
            "\", \"description\": \"An ENS Ethmoji Domain\", \"image_data\": \"",
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512'><rect width='100%' height='100%' fill='",
            (stillOwned ? (isPure ? "gold" : "grey") : "black"),
            "' /><text x='50%' y='55%' style='font-size: ",
            Strings.toString((!isPure && true/*stillOwned*/) ? px : emojiSize), // Number of emojis
            "px' dominant-baseline='middle' text-anchor='middle'>",
            true/*stillOwned*/ ? display : unicode"�", // Emoji
            "</text></svg>",
            "\"}"
        ))));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return tokenOwners[tokenId];
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return address(0);
    }

    function setApprovalForAll(address to, bool approved) public override {} // Stub 

    function isApprovedForAll(address owner, address to)
        public pure
        override
        returns (bool)
    {
        return false;
    }
    
    function balanceOf(address owner) public view override returns (uint256) {
        if (minted[owner] != 0) return 1; // Can only own one at a time
        return 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721) {
        require(from == address(0), "Token is domain bound.");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}