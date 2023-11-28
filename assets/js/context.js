import { 
  CENTER_X, loadTextures, handCardCoord, makeRenderer, makeStage, makePlayable, makeUnplayable,
  makeDeckSprite, makeTableSprite, makeHandSprites, makeHeldSprite,  makePlayerText,
  PLAYER_TURN_COLOR, NOT_PLAYER_TURN_COLOR, makeRoundText, makeTurnText,
} from "./canvas";

import { 
  updateTweens, handTweens, tweenWiggle, 
  tweenDeck, tweenTable, tweenTakeDeck, tweenTakeTable, tweenDiscard, tweenSwapTable 
} from "./tweens";

const HAND_SIZE = 6;

function rotate(arr, n) {
  return arr.slice(n).concat(arr.slice(0, n));
}

function initSprites() {
  return {
    deck: null,
    held: null,
    table: [],
    hands: { bottom: [], left: [], top: [], right: [], },
    players: {},
    round: null,
    turn: null,
  }
}

export class GameContext {
  constructor(game, parentEl, pushEvent) {
    this.game = game;
    this.parentEl = parentEl;
    this.pushEvent = pushEvent;

    this.stage = makeStage();
    this.renderer = makeRenderer();
    this.sprites = initSprites();

    loadTextures().then(textures => {
      this.textures = textures;
      this.parentEl.appendChild(this.renderer.view);
      this.addSprites();
      requestAnimationFrame(time => this.draw(time));
    });
  }

  draw(time) {
    requestAnimationFrame(time => this.draw(time));
    updateTweens(time);
    this.renderer.render(this.stage);
  }

  // sprites

  addSprites() {
    this.addRoundText();
    this.addTurnText();
    this.addDeck();

    if (this.game.state !== "no_round") {
      this.addTableCards();

      for (const player of this.game.players) {
        this.addHand(player);
        this.addPlayerText(player);

        if (player.heldCard) {
          this.addHeldCard(player);
        }
      }
    } else {
      this.game.players.forEach(p => this.addPlayerText(p));
    }
  }

  addDeck() {
    const sprite = makeDeckSprite(this.textures, this.game.state);
    
    this.sprites.deck = sprite;
    this.stage.addChild(sprite);

    if (this.isPlayable("deck")) {
      makePlayable(sprite, () => this.onDeckClick());
    }
  }

  addTableCards() {
    const card0 = this.game.tableCards[0];
    const card1 = this.game.tableCards[1];

    // add the second card first, so it's on bottom
    if (card1) {
      this.addTableCard(card1);
    }

    if (card0) {
      this.addTableCard(card0);

      if (this.isPlayable("table")) {
        makePlayable(this.sprites.table[0], () => this.onTableClick());
      }
    }
  }

  addTableCard(card) {
    const sprite = makeTableSprite(this.textures, card);
    
    this.sprites.table.unshift(sprite);
    this.stage.addChild(sprite);
  }

  addHand(player) {
    const sprites = makeHandSprites(this.textures, player.hand, player.position);
    const belongsToUser = player.id === this.game.playerId;

    sprites.forEach((sprite, i) => {
      if (belongsToUser && this.isPlayable(`hand_${i}`)) {
        makePlayable(sprite, () => this.onHandClick(player.id, i));
      }

      this.sprites.hands[player.position][i] = sprite;
      this.stage.addChild(sprite);
    });
  }

  addHeldCard(player) {
    const belongsToUser = player.id === this.game.playerId;
    const sprite = makeHeldSprite(this.textures, player.heldCard, player.position, belongsToUser);
    
    this.sprites.held = sprite;
    this.stage.addChild(sprite);

    if (this.isPlayable("held")) {
      makePlayable(sprite, () => this.onHeldClick());
    }
  }

  addPlayerText(player) {
    const text = makePlayerText(player);
    
    this.stage.addChild(text);
    this.sprites.players[player.position] = text;

    if (player.canAct) {
      text.style.fill = PLAYER_TURN_COLOR;
    }
  }

  updatePlayerTexts() {
    for (const player of this.game.players) {
      const sprite = this.sprites.players[player.position];
      const color = player.canAct ? PLAYER_TURN_COLOR : NOT_PLAYER_TURN_COLOR;
      
      sprite.text = `${player.username}(${player.score}pts)`;
      sprite.style.fill = color;
    }
  }

  addRoundText() {
    const text = makeRoundText(this.game.roundNum);
    this.stage.addChild(text);
    this.sprites.round = text;
  }

  addTurnText() {
    const text = makeTurnText(this.game.turn);
    this.stage.addChild(text);
    this.sprites.turn = text;
  }

  updateTurnText() {
    const turnSprite = this.sprites.turn;
    turnSprite.text = `Turn ${this.game.turn}`;
  }

  // server events

  onGameStart(game) {
    this.game = game;

    const roundSprite = this.sprites.round;
    roundSprite.text = `Round ${game.roundNum}`;

    let hands = [];

    const hostIndex = this.game.players.findIndex(p => p.user_id === this.game.hostId);
    if (hostIndex == null) throw new Error("host not found on game start");

    const players = rotate(this.game.players, hostIndex);

    for (let i = players.length-1; i >= 0; i--) {
      const player = players[i];
      this.addHand(player);

      const playerSprite = this.sprites.players[player.position];
      playerSprite.style.fill = PLAYER_TURN_COLOR;

      const tween = handTweens(player.position, this.sprites.hands[player.position]);
      hands.push(tween);
    };

    [...hands].reverse().forEach((tweens, i) => {
      [...tweens].reverse().forEach((tween, j) => {
        tween.delay((HAND_SIZE-1-j) * 150 + i * 1000)
          .start();

        // start tweening the deck after dealing the first row
        if (i === this.game.players.length-1 && j === 2) {
          tween.onComplete(() => {
            tweenDeck(this.sprites.deck)
              .start()
              .onComplete(() => {
                this.addTableCards();
                tweenTable(this.sprites.table[0])
                  .start();
              });
          });
        }
      });
    });
  }

  onRoundStart(game) {
    this.game = game;
    this.removeSprites();

    this.addDeck();
    this.sprites.deck.x = CENTER_X;

    this.addRoundText();
    this.addTurnText();

    for (const player of this.game.players) {
      this.addPlayerText(player);
    }

    this.onGameStart(game);
  }

  onGameEvent(game, event) {
    this.game = game;

    this.updatePlayerTexts();
    this.updateTurnText();

    switch (event.action) {
      case "flip":
        return this.onFlip(event);

      case "take_deck":
        return this.onTakeDeck(event);

      case "take_table":
        return this.onTakeTable(event);

      case "discard":
        return this.onDiscard(event);

      case "swap":
        return this.onSwap(event);

      default:
        throw new Error("event does not have a valid action", event);
    }
  }

  onFlip(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on flip");

    // get the sprite we need to update
    const handSprites = this.sprites.hands[player.position];
    const handSprite = handSprites[event.hand_index];
   
    // update the sprite's texture
    const cardName = player.hand[event.hand_index]["name"];
    handSprite.texture = this.textures[cardName];

    // wiggle the sprite
    const coord = handCardCoord(player.position, event.hand_index);
    tweenWiggle(handSprite, coord.x).start();

    handSprites.forEach((sprite, i) => {
      if (!this.isPlayable(`hand_${i}`)) {
        makeUnplayable(sprite);
      }
    });

    if (this.isPlayable("deck")) {
      makePlayable(this.sprites.deck, () => this.onDeckClick());
    }

    // a player could flip a hand card before the table card is drawn so we also need to check if it exists
    if (this.sprites.table[0] && this.isPlayable("table")) {
      makePlayable(this.sprites.table[0], () => this.onTableClick());
    }
  }

  onTakeDeck(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on take deck");

    this.addHeldCard(player);
    
    tweenTakeDeck(player.position, this.sprites.held, this.sprites.deck)
      .start();

    if (player.id === this.game.playerId) {
      makePlayable(this.sprites.held, () => this.onHeldClick())
      makeUnplayable(this.sprites.deck);

      if (this.sprites.table[0]) {
        makeUnplayable(this.sprites.table[0]);
      }

      const handSprites = this.sprites.hands[player.position];
      handSprites.forEach((sprite, i) => {
        makePlayable(sprite, () => this.onHandClick(player.id, i));
      });
    }
  }

  onTakeTable(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on take table");

    this.addHeldCard(player);
    
    tweenTakeTable(player.position, this.sprites.held, this.sprites.table.shift())
      .start();

    if (player.id === this.game.playerId) {
      makeUnplayable(this.sprites.deck);
      makePlayable(this.sprites.held, () => this.onHeldClick());

      const handSprites = this.sprites.hands[player.position];
      handSprites.forEach((sprite, index) => {
        makePlayable(sprite, () => this.onHandClick(player.id, index));
      });
    }
  }

  onDiscard(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on discard");

    this.addTableCard(this.game.tableCards[0]);

    tweenDiscard(player.position, this.sprites.table[0], this.sprites.held)
      .start();

    this.sprites.held = null;

    this.sprites.hands[player.position].forEach((sprite, i) => {
      if (!this.isPlayable(`hand_${i}`)) {
        makeUnplayable(sprite);
      }

      // if the game is over, flip all the player's cards
      if (this.game.isFlipped || this.game.state === "game_over" || this.game.state == "round_over") {
        const name = player.hand[i].name;
        sprite.texture = this.textures[name];
      }
    });

    if (this.isPlayable("deck")) {
      makePlayable(this.sprites.deck, () => this.onDeckClick());
    }

    if (this.isPlayable("table")) {
      makePlayable(this.sprites.table[0], () => this.onTableClick());
    }
  }

  onSwap(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on swap");

    // add table card
    this.addTableCard(this.game.tableCards[0]);

    // change hand card texture
    const index = event.hand_index;
    const card = player.hand[index].name;

    const handSprites = this.sprites.hands[player.position];
    const handSprite = handSprites[index];
    handSprite.texture = this.textures[card];

    tweenSwapTable(player.position, this.sprites.table[0], handSprite)
      .start();

    // remove held card
    this.sprites.held.visible = false
    this.sprites.held = null;

    // if this is the last round, flip all the player's cards
    if (this.game.isFlipped) {
      handSprites.forEach((sprite, i) => {
        const card = player.hand[i].name;
        sprite.texture = this.textures[card];
      });
    }

    // if this is the current user's action make their hand unplayable
    if (player.id === this.game.playerId) {
      for (const sprite of handSprites) {
        makeUnplayable(sprite);
      }
    }

    if (this.isPlayable("deck")) {
      makePlayable(this.sprites.deck, () => this.onDeckClick());
    }

    if (this.isPlayable("table")) {
      makePlayable(this.sprites.table[0], () => this.onTableClick());
    }
  }

  // client events

  onHandClick(playerId, handIndex) {
    this.pushEvent("card-click", { playerId, handIndex, place: "hand" });
  }

  onDeckClick() {
    this.pushEvent("card-click", { playerId: this.game.playerId, place: "deck" });
  }

  onTableClick() {
    this.pushEvent("card-click", { playerId: this.game.playerId, place: "table" });
  }

  onHeldClick() {
    this.pushEvent("card-click", { playerId: this.game.playerId, place: "held" });
  }

  // util

  isPlayable(place) {
    return this.game.playableCards.includes(place);
  }

  removeSprites() {
    while (this.stage.children[0]) {
      this.stage.removeChild(this.stage.children[0])
    }

    this.sprites = initSprites();
  }
}
