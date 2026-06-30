const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BatchExecutor", function () {
  async function deployFixture() {
    const [owner, sender, recipient1, recipient2, recipient3] = await ethers.getSigners();

    const BatchExecutor = await ethers.getContractFactory("BatchExecutor");
    const executor = await BatchExecutor.deploy(5);
    await executor.waitForDeployment();

    const initialSupply = ethers.parseUnits("1000000", 18);
    const MockToken = await ethers.getContractFactory("MockToken");
    const token = await MockToken.deploy("Mock Token", "MOCK", initialSupply);
    await token.waitForDeployment();

    await token.transfer(sender.address, ethers.parseUnits("10000", 18));

    return { owner, sender, recipient1, recipient2, recipient3, executor, token };
  }

  it("executes batch token transfer successfully", async function () {
    const { sender, recipient1, recipient2, executor, token } = await deployFixture();

    const amounts = [ethers.parseUnits("10", 18), ethers.parseUnits("20", 18)];
    const recipients = [recipient1.address, recipient2.address];

    await token.connect(sender).approve(await executor.getAddress(), amounts[0] + amounts[1]);

    await expect(
      executor
        .connect(sender)
        ["Transfer(address,address[],uint256[])"](await token.getAddress(), recipients, amounts)
    )
      .to.emit(executor, "TokenBatchExecuted")
      .withArgs(sender.address, await token.getAddress(), 2, amounts[0] + amounts[1]);

    expect(await token.balanceOf(recipient1.address)).to.equal(amounts[0]);
    expect(await token.balanceOf(recipient2.address)).to.equal(amounts[1]);
  });

  it("executes batch native transfer successfully", async function () {
    const { sender, recipient1, recipient2, executor } = await deployFixture();
    const amounts = [ethers.parseEther("0.1"), ethers.parseEther("0.2")];
    const total = amounts[0] + amounts[1];
    const recipients = [recipient1.address, recipient2.address];

    await expect(executor.connect(sender)["Transfer(address[],uint256[])"](recipients, amounts, { value: total }))
      .to.emit(executor, "NativeBatchExecuted")
      .withArgs(sender.address, 2, total);
  });

  it("reverts when recipients and amounts lengths mismatch", async function () {
    const { sender, recipient1, recipient2, executor, token } = await deployFixture();

    await token.connect(sender).approve(await executor.getAddress(), ethers.parseUnits("10", 18));

    await expect(
      executor.connect(sender)["Transfer(address,address[],uint256[])"](
        await token.getAddress(),
        [recipient1.address, recipient2.address],
        [1]
      )
    ).to.be.revertedWithCustomError(executor, "InvalidLength");
  });

  it("reverts native transfer when msg.value is wrong", async function () {
    const { sender, recipient1, recipient2, executor } = await deployFixture();
    const amounts = [ethers.parseEther("0.1"), ethers.parseEther("0.2")];
    const recipients = [recipient1.address, recipient2.address];

    await expect(
      executor.connect(sender)["Transfer(address[],uint256[])"](recipients, amounts, {
        value: ethers.parseEther("0.29"),
      })
    ).to.be.revertedWithCustomError(executor, "InvalidNativeValue");
  });

  it("reverts when recipient count exceeds maxRecipients", async function () {
    const { owner, sender, recipient1, recipient2, recipient3, executor, token } = await deployFixture();

    await executor.connect(owner).setMaxRecipients(2);
    await token.connect(sender).approve(await executor.getAddress(), 3);

    await expect(
      executor.connect(sender)["Transfer(address,address[],uint256[])"](
        await token.getAddress(),
        [recipient1.address, recipient2.address, recipient3.address],
        [1, 1, 1]
      )
    ).to.be.revertedWithCustomError(executor, "TooManyRecipients");
  });
});
