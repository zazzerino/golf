import { 
  loadTextures, deckX, makeContainer, makeRenderer,
  makeDeckSprite, makeTableSprite, makeHandSprites, makeHeldSprite,
  makePlayable, makeUnplayable
} from "./canvas";

function initSprites() {
  return {
    deck: null,
    held: null,
    table: [],
    hands: { bottom: [], left: [], top: [], right: [], },
  }
}

export class GameContext {
  constructor(game, parentEl, pushEvent) {
    this.game = game;
    this.parentEl = parentEl;
    this.pushEvent = pushEvent;

    this.renderer = makeRenderer();
    this.stage = makeContainer();

    this.sprites = initSprites();

    loadTextures().then(textures => {
      this.textures = textures;
      this.parentEl.appendChild(this.renderer.view);
      this.addSprites();
      requestAnimationFrame(time => this.draw(time));
    });
  }

  draw(_time) {
    requestAnimationFrame(time => this.draw(time));
    this.renderer.render(this.stage);
  }

  // sprites

  addSprites() {
    this.addDeck();

    if (this.game.state !== "no_round") {
      this.addTableCards();

      for (const player of this.game.players) {
        this.addHand(player);

        if (player.heldCard) {
          this.addHeldCard(player);
        }
      }
    }
  }

  addDeck() {
    const sprite = makeDeckSprite(this.textures, this.game.state);

    if (this.isPlayable("deck")) {
      makePlayable(sprite, () => this.onDeckClick());
    }

    this.sprites.deck = sprite;
    this.stage.addChild(sprite);
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
    const pos = player.position;
    const sprites = makeHandSprites(this.textures, player.hand, pos);
    const belongsToUser = player.id === this.game.playerId;

    sprites.forEach((sprite, i) => {
      if (belongsToUser && this.isPlayable(`hand_${i}`)) {
        makePlayable(sprite, () => this.onHandClick(player.id, i));
      }

      this.sprites.hands[pos][i] = sprite;
      this.stage.addChild(sprite);
    });
  }

  addHeldCard(player) {
    const sprite = makeHeldSprite(this.textures, player.heldCard, player.position);
    this.sprites.held = sprite;
    this.stage.addChild(sprite);

    if (this.isPlayable("held")) {
      makePlayable(sprite, () => this.onHeldClick());
    }
  }

  // server events

  onGameStart(game) {
    this.game = game;
    this.sprites.deck.x = deckX(game.state);
    this.addTableCards();

    for (const player of this.game.players) {
      this.addHand(player);

      if (player.heldCard) {
        this.addHeldCard(player);
      }
    }
  }

  onRoundStart(game) {
    this.game = game;

    this.removeSprites();
    this.addDeck();
    this.onGameStart(game);
  }

  onGameEvent(game, event) {
    this.game = game;

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

    const handSprites = this.sprites.hands[player.position];
    const handSprite = handSprites[event.hand_index];
    
    const cardName = player.hand[event.hand_index]["name"];
    handSprite.texture = this.textures[cardName];

    // tweenWiggle(handSprite).start();

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

    // tweenTakeDeck(player.position, heldSprite, this.sprites.deck).start();

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
    
    // remove table sprite
    const tableSprite = this.sprites.table.shift();
    tableSprite.visible = false;

    // tweenTakeTable(player.position, heldSprite, tableSprite).start();

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

    // add table card
    this.addTableCard(this.game.tableCards[0]);

    // remove held card
    this.sprites.held.visible = false;
    this.sprites.held = null;

    // tweenDiscard(player.position, this.sprites.table[0], this.sprites.held).start();

    this.sprites.hands[player.position].forEach((sprite, i) => {
      if (!this.isPlayable(`hand_${i}`)) {
        makeUnplayable(sprite);
      }

      // if the game is over, flip all the player's cards
      if (this.game.state === "game_over") {
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
    handSprites[index].texture = this.textures[card];

    // remove held card
    this.sprites.held.visible = false
    this.sprites.held = null;

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

  onDeckClick() {
    this.pushEvent("deck-click", { playerId: this.game.playerId });
  }

  onTableClick() {
    this.pushEvent("table-click", { playerId: this.game.playerId });
  }

  onHandClick(playerId, handIndex) {
    this.pushEvent("hand-click", { playerId, handIndex });
  }

  onHeldClick() {
    this.pushEvent("held-click", { playerId: this.game.playerId });
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
