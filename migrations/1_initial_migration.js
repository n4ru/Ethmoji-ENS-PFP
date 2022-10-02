const Migrations = artifacts.require("Migrations");

module.exports = function (deployer) {
  // Deploy the Validate contract first
  
  deployer.deploy(Migrations);
};
