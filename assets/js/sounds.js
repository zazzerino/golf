import {Howl} from "../vendor/howler.min.js";

const soundPlace1 = new Howl({
  src: ['/audio/cardPlace1.wav'],
});

const soundPlace2 = new Howl({
  src: ['/audio/cardPlace2.wav'],
  volume: 0.4,
});

const soundPlace3 = new Howl({
  src: ['/audio/cardPlace3.wav'],
  volume: 0.4,
});

const soundShove2 = new Howl({
  src: ['/audio/cardShove2.wav'],
  volume: 0.2,
});

const soundShove3 = new Howl({
  src: ['/audio/cardShove3.wav'],
  volume: 0.2,
});

export function playPlace1() {
  soundPlace1.play();
}

export function playPlace2() {
  soundPlace2.play();
}

export function playPlace3() {
  soundPlace3.play();
}

export function playShove2() {
  soundShove2.play();
}

export function playShove3() {
  soundShove3.play();
}
