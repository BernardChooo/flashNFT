pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./aave/FlashLoanReceiverBase.sol";
import "./aave/ILendingPoolAddressesProvider.sol";
import "./aave/ILendingPool.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";


interface iLeaseNFT {

        enum Status { PENDING, ACTIVE, CANCELLED, ENDED }


        struct LeaseOffer {
        uint leaseID;
        address payable lessor; // Owner of asset
        address payable lessee; // User of asset
        address smartContractAddressOfNFT;
        uint tokenIdNFT;
        uint collateralAmount;
        uint leasePrice;
        uint leasePeriod;
        uint endLeaseTimeStamp;
        Status status;}

    function acceptLeaseOffer(uint leaseID)external payable;
    function endLeaseOffer(uint leaseID)external;

    function allLeaseOffers(uint) external returns (LeaseOffer memory);
}

interface ERC721Vipers {
    struct Viper {
        uint8 genes;
        uint256 matronId;
        uint256 sireId;
    }
    
    function breedVipers(uint256 matronId, uint256 sireId) external returns (uint256);
}

contract SingleFlashNFT is FlashLoanReceiverBase {
    address LeaseNFTAddress;
    uint leaseID;
    address smartContractAddressOfNFT;
    uint NFTid;

    constructor(address _addressProvider, address _LeaseNFTAddress,uint _leaseID) FlashLoanReceiverBase(_addressProvider) payable public {
        LeaseNFTAddress = _LeaseNFTAddress;
        iLeaseNFT leaseInstance = iLeaseNFT(LeaseNFTAddress);
        smartContractAddressOfNFT = leaseInstance.allLeaseOffers(_leaseID).smartContractAddressOfNFT;
        NFTid = leaseInstance.allLeaseOffers(_leaseID).tokenIdNFT;

        addressesProvider = ILendingPoolAddressesProvider(_addressProvider);
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
        override
    {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");

        iLeaseNFT leaseInstance = iLeaseNFT(LeaseNFTAddress);

        leaseInstance.acceptLeaseOffer{value: leaseInstance.allLeaseOffers(leaseID).collateralAmount}(leaseID);

        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!

        // both NFTs have the same Contract address
        // ERC721Vipers instanceOfNFT = ERC721Vipers(smartContractAddressOfNFT1);
        // just breeding
        // instanceOfNFT.breedVipers(NFTid1, NFTid2);
        
        //
        /// Check NFT is returned to the Contract address.
        IERC721 NFTInstance = IERC721(smartContractAddressOfNFT);
        NFTInstance.approve(LeaseNFTAddress, NFTid);

        leaseInstance.endLeaseOffer(leaseID);

        require(NFTInstance.ownerOf(NFTid) == leaseInstance.allLeaseOffers(leaseID).lessor, "NFT has not been retured to original owner");

        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
        // (msg.sender).transfer(address(this).balance); // Send profit ETH back to Owner.
    }

    /**
        Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
        Enter Amount to loan and NFTid that you wish to lease on NFT.finance
     */
    function flashloan(uint _amount,uint _leaseID) public { // add onlyOwner
        iLeaseNFT leaseInstance = iLeaseNFT(LeaseNFTAddress);
        smartContractAddressOfNFT = leaseInstance.allLeaseOffers(_leaseID).smartContractAddressOfNFT;
        NFTid = leaseInstance.allLeaseOffers(_leaseID).tokenIdNFT;
        leaseID = _leaseID;

        bytes memory data = "";
        uint amount = _amount * 1 ether; // x 1e18

        address _asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // Ethereum
        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), _asset, amount, data);
    }

}
