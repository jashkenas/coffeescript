# @flow

###::
type Obj = {
  num: number,
};
###

fn = (str ###: string ###, obj ###: Obj ###) ###: string ### ->
  str + obj.num
