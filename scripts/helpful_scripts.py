from brownie import network, config, accounts, MockV3Aggregator

FORKED_LOCAL_ENVIRONMENTS = ["mainnet-fork", "mainnet-fork-dev"]
LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["development", "ganache-local"]

# decimals are 8 and not 18 because in get_price() we multiply by an additional 10 digits.
DECIMALS = 8
# This is 2,000$
STARTING_PRICE = 200000000000


def get_account():
    # if we are on the development chain we use account[0]
    # if not we use the method from our config.
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS
        or network.show_active() in FORKED_LOCAL_ENVIRONMENTS
    ):
        return accounts[0]
    else:
        return accounts.add(config["wallets"]["from_key"])


def deploy_mocks():
    print(f"The active network is {network.show_active()}")
    print("Deploying Mocks...")
    # MockV3Aggregator will be a list with all deployed MockV3Aggregators
    # if we have deployed it once we do not need to do it again.

    # if we change the mock we need to reset it, delete the folder with
    # the corresponding id. otherwise changes wont be updated.
    if len(MockV3Aggregator) <= 0:
        MockV3Aggregator.deploy(DECIMALS, STARTING_PRICE, {"from": get_account()})
    print("Mocks deployed.")
