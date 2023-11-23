import * as PIXI from "pixi.js";
import { OutlineFilter } from "@pixi/filter-outline";

const GAME_WIDTH = 600;
const GAME_HEIGHT = 600;

const CENTER_X = GAME_WIDTH / 2;
const CENTER_Y = GAME_HEIGHT / 2;

const CARD_IMG_WIDTH = 88;
const CARD_IMG_HEIGHT = 124;

const CARD_SCALE = 0.75;

const CARD_WIDTH = CARD_IMG_WIDTH * CARD_SCALE;
const CARD_HEIGHT = CARD_IMG_HEIGHT * CARD_SCALE;

const DECK_X = CENTER_X - CARD_WIDTH / 2;
const DECK_Y = CENTER_Y;

/**
The deck png has 5 pixels of cards below the top card.
This offset lets us place cards correctly on top of the deck.
*/
const DECK_Y_OFFSET = -5;

const TABLE_CARD_X = CENTER_X + CARD_WIDTH / 2 + 2;
const TABLE_CARD_Y = CENTER_Y;

const HAND_SIZE = 6;

const HAND_X_PAD = 3;
const HAND_Y_PAD = 10;

const DECK_CARD = "1B";
const DOWN_CARD = "2B";

const SPRITESHEET = "/images/spritesheets/cards.json";
const HOVER_CURSOR_STYLE = "url('/images/cursor-click.png'),auto";

const BG_COLOR = "forestgreen";

export function makeRenderer(width = GAME_WIDTH, height = GAME_HEIGHT, backgroundColor = BG_COLOR) {
  const renderer = new PIXI.Renderer({
    width,
    height,
    backgroundColor,
    antialias: true,
  });

  renderer.events.cursorStyles.hover = HOVER_CURSOR_STYLE;
  return renderer;
}

export function makeContainer() {
  return new PIXI.Container();
}

export async function bgLoadTextures(spritesheet = SPRITESHEET) {
  PIXI.Assets.backgroundLoad(spritesheet);
}

export async function loadTextures(spritesheet = SPRITESHEET) {
  return PIXI.Assets.load([spritesheet])
    .then(assets => assets[spritesheet].textures);
}

function makeCardSprite(texture, x = 0, y = 0, rotation = 0) {
  const sprite = PIXI.Sprite.from(texture);

  sprite.scale.set(CARD_SCALE, CARD_SCALE);
  sprite.anchor.set(0.5);
  sprite.x = x;
  sprite.y = y;
  sprite.rotation = rotation;

  return sprite;  
}

export function makeDeckSprite(textures, state) {
  const x = deckX(state);
  const texture = textures[DECK_CARD];
  return makeCardSprite(texture, x, DECK_Y);
}

export function makeTableSprite(textures, card) {
  return makeCardSprite(textures[card], TABLE_CARD_X, TABLE_CARD_Y);
}

export function makeHandSprites(textures, hand, pos) {
  const sprites = [];

  hand.forEach((card, i) => {
    const name = card["face_up?"] ? card.name : DOWN_CARD;
    const coord = handCardCoord(pos, i);
    const sprite = makeCardSprite(textures[name], coord.x, coord.y, coord.rotation);
    sprites.push(sprite);
  });

  return sprites;
}

export function makeHeldSprite(textures, card, pos) {
  const coord = heldCardCoord(pos);
  return makeCardSprite(textures[card], coord.x, coord.y, coord.rotation);
}

const PLAYABLE_FILTER = new OutlineFilter(2, 0xff00ff, 1.0);

export function makePlayable(sprite, callback) {
  sprite.eventMode = "static";
  sprite.cursor = "hover"
  sprite.filters = [PLAYABLE_FILTER];
  sprite.removeAllListeners();
  sprite.on("pointerdown", event => callback(event.currentTarget));
}

export function makeUnplayable(sprite) {
  sprite.eventMode = "none";
  sprite.cursor = "default";
  sprite.filters = [];
  sprite.removeAllListeners();
}

function rotationAt(pos) {
  return pos === "left" || pos === "right"
    ? toRadians(90)
    : 0;
}

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

export function deckX(state) {
  return state == "no_round" ? CENTER_X : DECK_X;
}

export function heldCardCoord(pos, yPad = HAND_Y_PAD) {
  let x, y;

  switch (pos) {
    case "bottom":
      x = CENTER_X + CARD_WIDTH * 2.5;
      y = GAME_HEIGHT - CARD_HEIGHT - yPad;
      break;

    case "left":
      x = CARD_HEIGHT + yPad;
      y = CENTER_Y + CARD_WIDTH * 2.75;
      break;

    case "top":
      x = CENTER_X - CARD_WIDTH * 2.5;
      y = CARD_HEIGHT + yPad;
      break;

    case "right":
      x = GAME_WIDTH - CARD_HEIGHT - yPad;
      y = CENTER_Y - CARD_WIDTH * 2.75
      break;

    default:
      throw new Error(`invalid pos: ${pos}`);
  }

  return { x, y, rotation: rotationAt(pos) }
}


export function handCardCoord(pos, index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x = 0, y = 0;

  if (pos === "bottom") {
    switch (index) {
      case 0:
        x = CENTER_X - CARD_WIDTH - xPad;
        y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPad * 1.3;
        break;

      case 1:
        x = CENTER_X;
        y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPad * 1.3;
        break;

      case 2:
        x = CENTER_X + CARD_WIDTH + xPad;
        y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPad * 1.3;
        break;

      case 3:
        x = CENTER_X - CARD_WIDTH - xPad;
        y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPad;
        break;

      case 4:
        x = CENTER_X;
        y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPad;
        break;

      case 5:
        x = CENTER_X + CARD_WIDTH + xPad;
        y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPad;
        break;
    }
  } else if (pos === "top") {
    switch (index) {
      case 0:
        x = CENTER_X + CARD_WIDTH + xPad;
        y = CARD_HEIGHT * 1.5 + yPad * 1.3;
        break;

      case 1:
        x = CENTER_X;
        y = CARD_HEIGHT * 1.5 + yPad * 1.3;
        break;

      case 2:
        x = CENTER_X - CARD_WIDTH - xPad;
        y = CARD_HEIGHT * 1.5 + yPad * 1.3;
        break;

      case 3:
        x = CENTER_X + CARD_WIDTH + xPad;
        y = CARD_HEIGHT / 2 + yPad;
        break;

      case 4:
        x = CENTER_X;
        y = CARD_HEIGHT / 2 + yPad;
        break;

      case 5:
        x = CENTER_X - CARD_WIDTH - xPad;
        y = CARD_HEIGHT / 2 + yPad;
        break;
    }
  } else if (pos === "left") {
    switch (index) {
      case 0:
        x = CARD_HEIGHT * 1.5 + yPad * 1.3;
        y = CENTER_Y - CARD_WIDTH - xPad;
        break;

      case 1:
        x = CARD_HEIGHT * 1.5 + yPad * 1.3;
        y = CENTER_Y;
        break;

      case 2:
        x = CARD_HEIGHT * 1.5 + yPad * 1.3;
        y = CENTER_Y + CARD_WIDTH + xPad;
        break;

      case 3:
        x = CARD_HEIGHT / 2 + yPad;
        y = CENTER_Y - CARD_WIDTH - xPad;
        break;

      case 4:
        x = CARD_HEIGHT / 2 + yPad;
        y = CENTER_Y;
        break;

      case 5:
        x = CARD_HEIGHT / 2 + yPad;
        y = CENTER_Y + CARD_WIDTH + xPad;
        break;
    }
  } else if (pos === "right") {
    switch (index) {
      case 0:
        x = GAME_WIDTH - CARD_HEIGHT * 1.5 - yPad * 1.3;
        y = CENTER_Y + CARD_WIDTH + xPad;
        break;

      case 1:
        x = GAME_WIDTH - CARD_HEIGHT * 1.5 - yPad * 1.3;
        y = CENTER_Y;
        break;

      case 2:
        x = GAME_WIDTH - CARD_HEIGHT * 1.5 - yPad * 1.3;
        y = CENTER_Y - CARD_WIDTH - xPad;
        break;

      case 3:
        x = GAME_WIDTH - CARD_HEIGHT / 2 - yPad;
        y = CENTER_Y + CARD_WIDTH + xPad;
        break;

      case 4:
        x = GAME_WIDTH - CARD_HEIGHT / 2 - yPad;
        y = CENTER_Y;
        break;

      case 5:
        x = GAME_WIDTH - CARD_HEIGHT / 2 - yPad;
        y = CENTER_Y - CARD_WIDTH - xPad;
        break;
    }
  }

  return { x, y, rotation: rotationAt(pos) };
}
