pragma solidity ^0.4.11;

import "../dependencies/DBC.sol";
import "../dependencies/Owned.sol";
import "./PriceFeedAdapter.sol";

/// @title Price Feed Template
/// @author Melonport AG <team@melonport.com>
/// @notice Routes external data to smart contracts
contract PriceFeed is PriceFeedAdapter, DBC, Owned {

    // TYPES

    struct Data  {
        uint timestamp; // Timestamp of last price update of this asset
        address price; // Price of asset quoted against `QUOTE_ASSET` times ten to the power of {decimals of this asset}
    }

    // FIELDS

    // Constant fields
    /// Note: Frequency is purely self imposed and for information purposes only
    uint constant INTERVAL = 120; // Frequency of updates in seconds
    uint constant VALIDITY = 60; // Time in seconds data is considered valid
    // Fields that are only changed in constructor
    /// Note: By definition the price of the quote asset against itself (quote asset) is always equals one
    address public QUOTE_ASSET; // Is the quote asset of a portfolio against which all other assets are priced against
    // Fields that can be changed by functions
    mapping (uint => mapping(address => Data)) public dataHistory; // Ordered data set // Address of asset quoted against `QUOTE_ASSET` times ten to the power of {decimals of this asset} => data of asset
    uint public lastUpdateId;
    address[] public availableAssets;

    // PRE, POST, INVARIANT CONDITIONS

    /*function isDataSet(address ofAsset) internal returns (bool) { return dataHistory[lastUpdateId][ofAsset].timestamp > 0; }
    function isDataValid(address ofAsset) internal returns (bool) { return now - dataHistory[lastUpdateId][ofAsset].timestamp <= VALIDITY; }
    function isEqualLength(address[] x, uint[] y) internal returns (bool) { return x.length == y.length; }
    function arrayNotEmpty(address[] x) constant returns (bool) { return x.length >= 1; }*/

    // CONSTANT METHODS

    // Get price feed specific information
    function getQuoteAsset() constant returns (address) { return QUOTE_ASSET; }
    function getInterval() constant returns (uint) { return INTERVAL; }
    function getValidity() constant returns (uint) { return VALIDITY; }
    // Get availability of assets
    function numAvailableAssets() constant returns (uint) { return availableAssets.length; }
    function getAssetAt(uint id) constant returns (address) { return availableAssets[id]; }
    // Get asset specific information

    /// Pre: Asset has been initialised
    /// Post: Returns boolean if data is valid
    function isValid(address ofAsset)
        constant
        pre_cond(isDataSet(ofAsset))
        returns (bool)
    {
        return now - dataHistory[lastUpdateId][ofAsset].timestamp <= VALIDITY;
    }

    /// Pre: Asset has been initialised and is active
    /// Post: Timestamp, where last updated not longer than `VALIDITY` seconds ago
    function getPrice(address ofAsset)
        constant
        pre_cond(isDataSet(ofAsset))
        pre_cond(isDataValid(ofAsset))
        returns (uint)
    {
        return dataHistory[lastUpdateId][ofAsset].timestamp;
    }

    /// Pre: Asset has been initialised and is active
    /// Post: Timestamp and price of asset, where last updated not longer than `VALIDITY` seconds ago
    function getData(address ofAsset)
        constant
        pre_cond(isDataSet(ofAsset))
        pre_cond(isDataValid(ofAsset))
        returns (uint, uint)
    {
        return (
            dataHistory[lastUpdateId][ofAsset].timestamp,
            dataHistory[lastUpdateId][ofAsset].price
        );
    }

    // NON-CONSTANT INTERNAL METHODS

    function next_id() internal returns (uint) {
        lastUpdateId++; return lastUpdateId;
    }

    // NON-CONSTANT PUBLIC METHODS

    /// Pre: Define a quote asset against which all prices are measured/based against
    /// Post: Price Feed contract w Backup Owner
    function PriceFeed(address ofQuoteAsset, address[] ofAvailableAssets)
        pre_cond(arrayNotEmpty(ofAvailableAssets))
    {
        QUOTE_ASSET = ofQuoteAsset;
        availableAssets = ofAvailableAssets;
    }

    /// Pre: Only Owner; Same sized input arrays
    /// Post: Update price of asset relative to QUOTE_ASSET
    /** Ex:
     *  Let QUOTE_ASSET == ETH (in Wei), let asset == EUR-T, let Value of 1 EUR-T := 1 EUR == 0.080456789 ETH
     *  and let EUR-T decimals == 8,
     *  => dataHistory[lastUpdateId][EUR-T].price = 8045678 [Wei/ (EUR-T * 10**8)]
     */
    function update(address[] ofAssets, uint[] newPrices)
        pre_cond(isOwner())
        pre_cond(isEqualLength(ofAssets, newPrices))
    {
        for (uint i = 0; i < ofAssets.length; ++i) {
            assert(dataHistory[lastUpdateId][ofAsset[i]].timestamp != now); // Intended to prevent several updates w/in one block, eg w different prices
            dataHistory[next_id()][ofAsset[i]] = Data({
                timestamp: now,
                price: newPrices[i]
            });
        }
        PriceUpdated(lastUpdateId);
    }
}
