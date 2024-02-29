#Staking Gas Optimization

Gas before
·------------------------------------------------------------|----------------------------|-------------------|-----------------------------·
|                    Solc version: 0.4.25                    ·  Optimizer enabled: false  ·  Runs: undefined  ·  Block limit: 12000000 gas  │
·····························································|····························|···················|······························
|  Methods                                                                                                                                  │
························|····································|··············|·············|···················|···············|··············
|  Contract             ·  Method                            ·  Min         ·  Max        ·  Avg              ·  # calls      ·  usd (avg)  │
························|····································|··············|·············|···················|···············|··············
|  StakingRewards       ·  exit                              ·      172775  ·     243975  ·           208375  ·            2  ·          -  │
························|····································|··············|·············|···················|···············|··············
|  StakingRewards       ·  getReward                         ·      138477  ·     189444  ·           167652  ·            4  ·          -  │
························|····································|··············|·············|···················|···············|··············
|  StakingRewards       ·  notifyRewardAmount                ·       67293  ·     119112  ·           109610  ·           18  ·          -  │
························|····································|··············|·············|···················|···············|··············
|  StakingRewards       ·  recoverERC20                      ·           -  ·          -  ·            64686  ·            4  ·          -  │
························|····································|··············|·············|···················|···············|··············
|  StakingRewards       ·  setPaused                         ·       30279  ·      52404  ·            46873  ·            4  ·          -  │
························|····································|··············|·············|···················|···············|··············
|  StakingRewards       ·  setRewardsDistribution            ·       29005  ·      29017  ·            29013  ·            3  ·          -  │
························|····································|··············|·············|···················|···············|··············
|  StakingRewards       ·  setRewardsDuration                ·       32018  ·      32030  ·            32027  ·            4  ·          -  │
························|····································|··············|·············|···················|···············|··············
|  StakingRewards       ·  stake                             ·           -  ·          -  ·           146866  ·           12  ·          -  │
························|····································|··············|·············|···················|···············|··············
|  StakingRewards       ·  withdraw                          ·       99038  ·     175723  ·           137381  ·            2  ·          -  │
·····························································|··············|·············|···················|···············|··············
|  StakingRewards                                            ·           -  ·          -  ·          2388038  ·       19.9 %  ·          -  │
·------------------------------------------------------------|--------------|-------------|-------------------|---------------|-------------·