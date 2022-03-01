const Ethpool = artifacts.require("Ethpool");

module.exports = async function (deployer,network,accounts) {
  await deployer.deploy(Ethpool);
  let ethpool = await Ethpool.deployed();
  await ethpool.deposit({from: accounts[1],value:60000000000});
  await ethpool.deposit({from: accounts[2],value:80000000000});



  let share1 = await ethpool.getShare(accounts[1]);

  console.log("share of accout1: " + share1);
  
  await ethpool.grantTeamRole(accounts[3]);
  await ethpool.deposit({from: accounts[3],value:100000000000});
  
  let prize = ethpool.getPrize();

  console.log("price" + prize);

 

  
};
