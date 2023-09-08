# Pools mini FAQ

## Pool Commision and Beneficiary

Pool commission can be in one of these states:
1. Both beneficiary and pool commission set.
2. Both beneficiary and pool commission not set.

First case means that all commission will be deposited to beneficiary account. Second case means there's no commission at all.

## What does it mean that a pool doesn't have commission rate. Does it mean no commission?

Yes. pool commission is optional. That means when these parameters not set if there's no commission set.

## What does it mean if commission max value is null? there's no commission on the pool?

It means that there is no max commission set on the pool. But still there can be a commission or a commission change rate. And because max commission is not set, it means that the actual commission can be changed at any time to any value.

Importantly, max commission can not be removed once set, and can only be set to more restrictive values (i.e. a lower max commission) in subsequent updates.

## What does it mean if commission change rate value is null? there's no commission on the pool?

That means that there is no commission change rate on the pool. But still there can be commission or max commission.

Importantly, commission change rate can not be removed once set, and can only be set to more restrictive values (i.e. a slower change rate) in subsequent updates.

## Is point to balance ration always 1:1?

A unit of measure for a members portion of a pool's funds. Points initially have a  ratio of 1 (as set by `POINTS_TO_BALANCE_INIT_RATIO`) to balance, but as slashing happens, this can change.

Slashing does not change any single member's balance. Instead, the slash will only reduce the balance associated with a particular pool. But, we never change the total *points* of a pool because of slashing. Therefore, when a slash happens, the ratio of points to balance changes in
a pool. In other words, the value of one point, which is initially 1-to-1 against a unit of balance, is now less than one balance because of the slash.
