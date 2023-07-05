// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

contract ManualToken {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // creates an array with all the balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     *
     */
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) {
        totalSupply = initialSupply * 10 ** uint256(decimals); // update total supply with decimal amount
        balanceOf[msg.sender] = totalSupply; // give creator all initial tokens
        name = tokenName; // set token name for display purposes
        symbol = tokenSymbol; // set token symbol for display purposes
    }

    /**
     * Internal transfer, can only be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        // prevent transfer to 0x0 address, use burn() instead
        require(_to != address(0x0));
        // check if sender has enough
        require(balanceOf[_from] >= _value);
        // overflow check
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // save this for assertion in future
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        // subtract value from sender
        balanceOf[_from] -= _value;
        // add value to receiver
        balanceOf[_to] += _value;
        // fire transfer event
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer okens
     *
     * Send '_value' tokens to '_to' from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send '_value' tokens to '_to' on behalf of '_from'
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows '_spender' to spend no more than '_value' tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows '_spender' to spend no more than '_value' tokens on your behalf, then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData Some extra information to send to the approved contract
     */
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * Burn Tokens
     *
     * Remove '_value' tokens from the system irreversibely
     *
     * @param _value The amount of tokens to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value); // check that sender has enough tokens
        balanceOf[msg.sender] -= _value; // subtract tokens from sender's balance
        totalSupply -= _value; // subtract tokens from totalySupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove '_value' tokens from the system irreversibly on behalf of '_from'
     *
     * @param _from The address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value); // check that targeted balance is enough
        require(_value <= allowance[_from][msg.sender]); // check allowance
        balanceOf[_from] -= _value; // subtract tokens from targeted balance
        allowance[_from][msg.sender] -= _value; // subtract tokens from sender's allowance
        totalSupply -= _value; // subtract tokens from total supply
        emit Burn(_from, _value);
        return true;
    }
}
