var volume, winner;
if (ignition === true) {
  launch();
}
if (band !== SpinalTap) {
  volume = 10;
}
if (answer !== false) {
  letTheWildRumpusBegin();
}
if (car.speed < limit) {
  accelerate();
}
if ((47 === pick || 92 === pick || 13 === pick)) {
  winner = true;
}
print(inspect("My name is " + this.name));