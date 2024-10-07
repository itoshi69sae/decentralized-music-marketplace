// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

contract Music {

  struct Song{
    string name;
    uint price;
    address artist;
    string artistName;
  }
// stores address with the user type
 mapping (address => string) public  userType;
// Links user name with a corressponding address
 mapping  (address =>string) public  userName;
 mapping (string => address) public userAddress;
// mapping of unique song hash with song metadata
 mapping (bytes32 =>Song) private  songs;
// stores songs owned by each artist
 mapping (address => Song[]) private songsList;

// event for each function completion
 event SongAdded (bytes32 songId, string indexed artistName ,string songName ,uint songPrice);
 event songPurchased (string indexed userName ,bytes32 songId ,string indexed artistName ,string songName);
 event Donation (string indexed Donor ,string indexed songArtist ,uint donationAmount);

  function registerUser(address _user, bool val,string memory _userName) public  {
    // if the address has already been assigned a type then it is already registered
    if(keccak256(abi.encodePacked((userType[_user]))) == keccak256(abi.encodePacked(("Artists")))||keccak256(abi.encodePacked((userType[_user]))) == keccak256(abi.encodePacked(("Listeners")))){
      revert("User already Exists");
    }
    // extra checks if user is already registered
    require(userAddress[_userName]==address(0),"UserName already exists");
    require(keccak256(abi.encodePacked((userName[_user]))) == keccak256(abi.encodePacked((""))),"Username already exists");
    if(val){
      userType[_user] = "Artists";
    }
    else{
      userType[_user] = "Listeners";
    }
    userName[_user] = _userName;
    userAddress[_userName] = _user;
    
  }
  function DonateToArtist(string memory _artist,uint _amount) public payable{
  // checks if user is registered
    require(userAddress[_artist]!=address(0),"invalid artist");
    require(userAddress[_artist]!=msg.sender,"can't donate self");
  // checks if sufficient funds are given
     require(msg.value>=_amount,"insufficient funds");
     require(_amount>0,"Insufficient funds");
     (bool sent, bytes memory data) = userAddress[_artist].call{value: _amount }("");
     require(sent, "Failed to send Ether");
     emit Donation(userName[msg.sender],_artist,_amount);
  }
  function buySong(string memory _songName,string memory _songArtist) public payable  {
     bytes32 songHash = keccak256(abi.encodePacked(_songArtist,_songName));
      require(songs[songHash].price != 0 && songs[songHash].artist !=address(0),"Song doesn't exists");
    Song memory song = songs[songHash];
    for(uint i=0;i < songsList[msg.sender].length;i++){
      if(keccak256(abi.encodePacked(song.artist)) == keccak256(abi.encodePacked(songsList[msg.sender][i].artist)) && keccak256(abi.encodePacked(song.name)) == keccak256(abi.encodePacked(songsList[msg.sender][i].name)) ){
        revert("Song already Bought");
      }
    }
    require(msg.value>=song.price,"insufficient funds");
    (bool sent, bytes memory data) = (song.artist).call{value: song.price }("");
    require(sent, "Failed to send Ether");
    songsList[msg.sender].push(song);
    emit songPurchased(userName[msg.sender],songHash,song.artistName,song.name);
  }
  
  function uploadSongs(string memory _songName,uint24 _price) public  {
    require(_price > 0,"Not a valid Price");
    require(keccak256(abi.encodePacked(userType[msg.sender])) == keccak256(abi.encodePacked(("Artists"))),"Not authorised");
    bytes32 songHash = keccak256(abi.encodePacked(userName[msg.sender],_songName));
    require(songs[songHash].price == 0 && songs[songHash].artist ==address(0),"Song already exists");
    
    Song memory  newSong;
    newSong.name = _songName;
    newSong.artistName = userName[msg.sender];
    newSong.artist = msg.sender;
    newSong.price = _price;
    
    songs[songHash] = newSong;
    songsList[msg.sender].push(newSong);
    emit SongAdded(songHash,userName[msg.sender],_songName,_price);
  }

  
}

