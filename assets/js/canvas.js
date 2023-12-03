// import * as PIXI from "../vendor/pixi.min.mjs";
import { OutlineFilter } from "../vendor/pixi-filters.mjs";

const CARD_IMG_WIDTH = 88;
const CARD_IMG_HEIGHT = 124;

const CARD_SCALE = 0.75;

const CARD_WIDTH = CARD_IMG_WIDTH * CARD_SCALE;
const CARD_HEIGHT = CARD_IMG_HEIGHT * CARD_SCALE;

const GAME_WIDTH = 600;
const GAME_HEIGHT = 600;

const DECK_TABLE_OFFSET = 4;

export const CENTER_X = GAME_WIDTH / 2;
export const CENTER_Y = GAME_HEIGHT / 2;

export const DECK_X = CENTER_X - CARD_WIDTH / 2 - DECK_TABLE_OFFSET;
export const DECK_Y = CENTER_Y;

export const TABLE_CARD_X = CENTER_X + CARD_WIDTH / 2 + DECK_TABLE_OFFSET;
export const TABLE_CARD_Y = CENTER_Y;

const HAND_X_PAD = 3;
const HAND_Y_PAD = 10;

const DECK_CARD = "1B";
const DOWN_CARD = "2B";

const SPRITESHEET = "/images/spritesheets/cards.json";
const HOVER_CURSOR_STYLE = "url('/images/cursor-click.png'),auto";

const BG_COLOR = "forestgreen";

export const PLAYER_TURN_COLOR = "#00ff00";
export const NOT_PLAYER_TURN_COLOR = "#ff77ff";

const PLAYABLE_FILTER = new OutlineFilter(3, 0x00ffff, 0.5);

export async function bgLoadTextures(spritesheet = SPRITESHEET) {
  PIXI.Assets.backgroundLoad(spritesheet);
}

export async function loadTextures(spritesheet = SPRITESHEET) {
  return PIXI.Assets.load([spritesheet])
    .then(assets => {
      console.log("assets", assets)
      return assets[spritesheet].textures;
    });
}

export function makeRenderer(width = GAME_WIDTH, height = GAME_HEIGHT, backgroundColor = BG_COLOR) {
  const renderer = new PIXI.Renderer({
    width,
    height,
    backgroundColor,
    // antialias: true,
    // resolution: window.devicePixelRatio || 1,
    // autoDensity: true,
  });

  renderer.events.cursorStyles.hover = HOVER_CURSOR_STYLE;
  return renderer;
}

export function makeStage() {
  return new PIXI.Container();
}

// sprites

function makeCardSprite(texture, x = 0, y = 0, rotation = 0) {
  // texture.baseTexture.scaleMode = PIXI.SCALE_MODES.NEAREST;
  const sprite = PIXI.Sprite.from(texture);

  sprite.scale.set(CARD_SCALE, CARD_SCALE);
  sprite.anchor.set(0.5);
  sprite.x = x;
  sprite.y = y;
  sprite.rotation = rotation;

  return sprite;  
}

export function makeJokerSprite(x = 0, y = 0) {
  const bgRect = new PIXI.Graphics();
  bgRect.lineStyle(1)
  bgRect.beginFill(0xffffff);
  bgRect.drawRect(x - CARD_WIDTH / 2, y - CARD_HEIGHT / 2, CARD_WIDTH, CARD_HEIGHT);

  const style = new PIXI.TextStyle({
    fontFamily: "monospace",
    fontSize: 42,
  });

  const text = new PIXI.Text("JK", style);
  text.x = x;
  text.y = y;
  text.anchor.set(0.5, 0.5);

  const container = new PIXI.Container();
  container.addChild(bgRect);
  container.addChild(text);

  return container;
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

export function makeHeldSprite(textures, card, pos, belongsToUser = true) {
  const coord = heldCardCoord(pos);
  const texture = belongsToUser ? textures[card] : textures[DOWN_CARD];
  return makeCardSprite(texture, coord.x, coord.y, coord.rotation);
}

// text

export function makePlayerText(player, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  const style = new PIXI.TextStyle({
    fill: NOT_PLAYER_TURN_COLOR,
    fontFamily: "monospace",
  });

  const points = player.score === 1 || player.score === -1 ? "pt" : "pts";
  const content = `${player.username}(${player.score}${points})`;
  const text = new PIXI.Text(content, style);

  switch (player.position) {
    case "bottom":
      text.x = GAME_WIDTH / 2;
      text.y = GAME_HEIGHT - 5;
      text.anchor.set(0.5, 1.0);
      break;

    case "top":
      text.x = GAME_WIDTH / 2;
      text.y = 5;
      text.anchor.set(0.5, 0.0);
      break;

    case "left":
      text.x = CARD_HEIGHT + yPad;
      text.y = CENTER_Y - CARD_HEIGHT * 2;
      text.anchor.set(0.5, 0.0);
      break;

    case "right":
      text.x = GAME_WIDTH - CARD_HEIGHT - yPad;
      text.y = CENTER_Y - CARD_HEIGHT * 2;
      text.anchor.set(0.5, 0.0);
      break;
      
    default:
      throw new Error(`invalid pos: ${pos}`);
  }

  return text;
}

export function makeRoundText(roundNum) {
  const style = new PIXI.TextStyle({
    fill: NOT_PLAYER_TURN_COLOR,
    fontFamily: "monospace",
  });

  const content = `Round ${roundNum}`;
  const text = new PIXI.Text(content, style);
  text.x = 5;
  text.y = 5;
  return text;
}

export function makeTurnText(turn) {
  const style = new PIXI.TextStyle({
    fill: NOT_PLAYER_TURN_COLOR,
    fontFamily: "monospace",
  });

  const content = `Turn ${turn}`;
  const text = new PIXI.Text(content, style);
  text.anchor.set(0.0, 0.0);
  text.x = 5;
  text.y = 35;
  return text;
}

export function makeOverText(winnerName) {
  const style = new PIXI.TextStyle({
    fontFamily: "monospace",
    fontSize: 48,
    // fill: NOT_PLAYER_TURN_COLOR,
    // fill: 0xffc0cb,
    fill: 0xffffff,
    // fill: 0xff69b4,
    // fill: 0xffff00,
  });

  const content = `${winnerName} wins!`.toUpperCase();
  const text = new PIXI.Text(content, style);
  text.x = CENTER_X;
  text.y = CENTER_Y;
  text.anchor.set(0.5, 0.5);

  let bgRect = new PIXI.Graphics();
  // bg.beginFill(0x0000ff);
  bgRect.beginFill(0x0088ff);
  bgRect.drawRect(CENTER_X-200, CENTER_Y-60, 400, 120);

  const container = new PIXI.Container();
  container.addChild(bgRect);
  container.addChild(text);

  return container;
}

// interactive

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

// coords

export function deckX(state) {
  return state == "no_round" ? CENTER_X : DECK_X;
}

export function heldCardCoord(pos, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x, y;

  switch (pos) {
    case "bottom":
      x = CENTER_X + CARD_WIDTH * 2.5;
      y = GAME_HEIGHT - CARD_HEIGHT - yPad - 30;
      break;

    case "top":
      x = CENTER_X - CARD_WIDTH * 1.5;
      y = CARD_HEIGHT + 1.3 * yPad + 30;
      break;

    case "left":
      x = CARD_WIDTH + yPad + 5;
      y = CENTER_Y + CARD_HEIGHT * 1.5 + xPad;
      break;

    case "right":
      x = GAME_WIDTH - CARD_WIDTH - yPad - 5;
      y = CENTER_Y + CARD_HEIGHT * 1.5 + xPad;
      break;

    default:
      throw new Error(`invalid pos: ${pos}`);
  }

  return {x, y, rotation: 0};
}

function handCardBottomCoord(index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x = 0, y = 0;

  switch (index) {
    case 0:
      x = CENTER_X - CARD_WIDTH - xPad;
      y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPad * 1.3 - 30;
      break;

    case 1:
      x = CENTER_X;
      y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPad * 1.3 - 30;
      break;

    case 2:
      x = CENTER_X + CARD_WIDTH + xPad;
      y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPad * 1.3 - 30;
      break;

    case 3:
      x = CENTER_X - CARD_WIDTH - xPad;
      y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPad - 30;
      break;

    case 4:
      x = CENTER_X;
      y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPad - 30;
      break;

    case 5:
      x = CENTER_X + CARD_WIDTH + xPad;
      y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPad - 30;
      break;

    default:
      throw new Error(`index ${index} out of range`);
  }

  return {x, y, rotation: 0};
}

function handCardTopCoord(index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x = 0, y = 0;

  switch (index) {
    case 0:
      x = CENTER_X + CARD_WIDTH + xPad;
      y = CARD_HEIGHT * 1.5 + yPad * 1.3 + 30;
      break;

    case 1:
      x = CENTER_X;
      y = CARD_HEIGHT * 1.5 + yPad * 1.3 + 30;
      break;

    case 2:
      x = CENTER_X - CARD_WIDTH - xPad;
      y = CARD_HEIGHT * 1.5 + yPad * 1.3 + 30;
      break;

    case 3:
      x = CENTER_X + CARD_WIDTH + xPad;
      y = CARD_HEIGHT / 2 + yPad + 30;
      break;

    case 4:
      x = CENTER_X;
      y = CARD_HEIGHT / 2 + yPad + 30;
      break;

    case 5:
      x = CENTER_X - CARD_WIDTH - xPad;
      y = CARD_HEIGHT / 2 + yPad + 30;
      break;
  }

  return {x, y, rotation: 0};
}

function handCardLeftCoord(index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x = 0, y = 0;

  switch (index) {
    case 0:
      x = CARD_WIDTH * 1.5 + yPad * 1.3 + 5;
      y = CENTER_Y - CARD_HEIGHT - xPad;
      break;

    case 1:
      x = CARD_WIDTH * 1.5 + yPad * 1.3 + 5;
      y = CENTER_Y;
      break;

    case 2:
      x = CARD_WIDTH * 1.5 + yPad * 1.3 + 5;
      y = CENTER_Y + CARD_HEIGHT + xPad;
      break;

    case 3:
      x = CARD_WIDTH / 2 + yPad;
      y = CENTER_Y - CARD_HEIGHT - xPad;
      break;

    case 4:
      x = CARD_WIDTH / 2 + yPad;
      y = CENTER_Y;
      break;

    case 5:
      x = CARD_WIDTH / 2 + yPad;
      y = CENTER_Y + CARD_HEIGHT + xPad;
      break;
  }

  return {x, y, rotation: 0};
}

function handCardRightCoord(index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x = 0, y = 0;

  switch (index) {
    case 0:
      x = GAME_WIDTH - CARD_WIDTH * 1.5 - yPad * 1.3 - 5;
      y = CENTER_Y + CARD_HEIGHT + xPad;
      break;

    case 1:
      x = GAME_WIDTH - CARD_WIDTH * 1.5 - yPad * 1.3 - 5;
      y = CENTER_Y;
      break;

    case 2:
      x = GAME_WIDTH - CARD_WIDTH * 1.5 - yPad * 1.3 - 5;
      y = CENTER_Y - CARD_HEIGHT - xPad;
      break;

    case 3:
      x = GAME_WIDTH - CARD_WIDTH / 2 - yPad;
      y = CENTER_Y + CARD_HEIGHT + xPad;
      break;

    case 4:
      x = GAME_WIDTH - CARD_WIDTH / 2 - yPad;
      y = CENTER_Y;
      break;

    case 5:
      x = GAME_WIDTH - CARD_WIDTH / 2 - yPad;
      y = CENTER_Y - CARD_HEIGHT - xPad;
      break;
  }

  return {x, y, rotation: 0};
}

export function handCardCoord(pos, index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  switch (pos) {
    case "bottom":
      return handCardBottomCoord(index, xPad, yPad);
    case "top":
      return handCardTopCoord(index, xPad, yPad);
    case "left":
      return handCardLeftCoord(index, xPad, yPad);
    case "right":
      return handCardRightCoord(index, xPad, yPad);
    default:
      throw new Error(`invalid position: ${pos}`);
  }
}

// export const DISCARD_FILTER = new OutlineFilter(3, 0xff5500, 0.5);

// function toRadians(degrees) {
//   return degrees * (Math.PI / 180);
// }

// export function rotationAt(pos) {
//   return pos === "left" || pos === "right"
//     ? toRadians(90)
//     : 0;
// }
