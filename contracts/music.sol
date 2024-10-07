// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

contract Music {

  struct Song{
    string name;
    uint24 price;
    address artist;
    string artistName;
  }
 mapping (address => string) public  userType;
 mapping  (address =>string) public  userName;
 mapping (string => address) public userAddress;
 mapping (bytes32 =>Song) private  songs;
 mapping (address => Song[]) private songsList;

 event SongAdded (bytes32 songId, string indexed artistName ,string songName ,uint24 songPrice);
 event songPurchased (string indexed userName ,bytes32 songId ,string indexed artistName ,string songName);
 event Donation (string indexed Donor ,string indexed songArtist ,uint donationAmount);

  function registerUser(address _user, bool val,string memory _userName) public  {
    if(keccak256(abi.encodePacked((userType[_user]))) == keccak256(abi.encodePacked(("Artists")))||keccak256(abi.encodePacked((userType[_user]))) == keccak256(abi.encodePacked(("Listeners")))){
      revert("User already Exists");
    }
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
    if(keccak256(abi.encodePacked((userType[msg.sender]))) != keccak256(abi.encodePacked(("Artists")))&&keccak256(abi.encodePacked((userType[msg.sender]))) != keccak256(abi.encodePacked(("Listeners")))){
      revert("User doesn't Exist");
    }
    require(userAddress[_artist]!=address(0),"invalid artist");
    require(userAddress[_artist]!=msg.sender,"invalid user");
     require(msg.value>=_amount,"insufficient funds");
     require(_amount>0,"Please pay greater than zero");
     (bool sent, bytes memory data) = userAddress[_artist].call{value: _amount }("");
     require(sent, "Failed to send Ether");
     emit Donation(userName[msg.sender],_artist,_amount);
  }
  function buySong(string memory _songName,string memory _songArtist) public payable  {
     if(keccak256(abi.encodePacked((userType[msg.sender]))) != keccak256(abi.encodePacked(("Artists")))||keccak256(abi.encodePacked((userType[msg.sender]))) != keccak256(abi.encodePacked(("Listeners")))){
      revert("User doesn't Exist");
    }
     bytes32 songHash = keccak256(abi.encodePacked(_songArtist,_songName));
      require(songs[songHash].price != 0 && songs[songHash].artist !=address(0),"Song doesn't exist");
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
    require(keccak256(abi.encodePacked((userType[msg.sender]))) == keccak256(abi.encodePacked(("Artists"))),"Not authorised");
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
  function getSongPrice(string memory _artist,string memory _songName) public view returns(uint24){
     bytes32 songHash = keccak256(abi.encodePacked(_artist,_songName));
     require(songs[songHash].price !=0 && songs[songHash].artist !=address(0),"Song doesn't exist");
     require(keccak256(abi.encodePacked(userType[msg.sender])) == keccak256(abi.encodePacked(("Listeners"))) || keccak256(abi.encodePacked(userType[msg.sender])) == keccak256(abi.encodePacked(("Artists"))),"Not authorised");
     return songs[songHash].price;
   }
  
}
