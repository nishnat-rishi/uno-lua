cardsImg = love.graphics.newImage('deck.png')
cardDimensions = {x = 240, y = 360}
quadFiller = {cardDimensions.x+2, cardDimensions.y+2, cardsImg:getDimensions()}

gameState = 'RUNNING'

gX, gY = 0, 0

gameOverMessage = ''

function createGame(properties, players, handSize, minPlayers, maxPlayers)
    math.randomseed(os.time())
    game = {
        minPlayers = minPlayers or 2,
        maxPlayers = maxPlayers or 10,
        playerGroup = _createPlayerGroup(players),
        deck = {},
        pile = {},
        handSize = handSize or 7,
        -- _states = {},
        setPlayers = function(self, players)
            self.playerGroup = _createPlayerGroup(players)
        end,
        reshufflePileAsDeck = function(self)
            while (#self.pile.cards > 0) do
                self:addToDeck(self.pile:remove(1)) -- should be like this: self.deck:add(self.pile:remove(1))
                -- can't do directly since deck is being used as deck[math.random(#deck)]. this might cause trouble? (but functions will be as string, so no trouble hmmm)
            end
        end,
        reshufflePileAsDeckExcept = function(self, topCards)
            while (#self.pile.cards > topCards) do
                self:addToDeck(self.pile:remove(1))
            end
        end,
        preGame = function(self)
            self.playerGroup:setStep(1)
            for i = 1, self.playerGroup:size() do
                for j = 1, self.handSize do
                    self:currentPlayer().hand:add(table.remove(self.deck, math.random(#self.deck)))
                end
                self.playerGroup:changePlayer()
            end
        end,
        draw = function(self)
            self.pile:draw()
            self:currentPlayer():draw()
        end,
        update = function(self)
            self:currentPlayer():update()
        end,
        randomDraw = function(self)
            if #deck > 0 then
                return table.remove(self.deck, math.random(#self.deck))
            end
        end,
        randomDrawBetween = function(self, first, last)
            if #deck > 0 then
                r = math.random(last - first + 1)
                return table.remove(self.deck, first + r - 1)
            end
        end,
        addToDeck = function(self, card)
            table.insert(deck, card)
        end,
        setSequence = function(self, start, step)
            self.playerGroup:setSequence(start, step)
        end,
        nextTurn = function(self)
            self:redoNextTurnChanges()
        end,
        previousTurn = function(self)
            self:undoNextTurnChanges()
        end,
        redoNextTurnChanges = function(self)
            self.playerGroup:changePlayer()
            -- table.insert(_states, self)
        end,
        undoNextTurnChanges = function(self)
            self.playerGroup:undoChange()
            -- self = table.remove(_states)
        end,
        currentPlayer = function(self)
            return self.playerGroup:currentPlayer()
        end,
        nextPlayer = function(self)
            return self.playerGroup:nextPlayer()
        end,
        getActivePlayerIndex = function(self)
            return self.playerGroup.activePlayerIndex
        end,
        getStep = function(self)
            return self.playerGroup.step
        end
    }
    if properties ~= nil then
        for k, v in pairs(properties) do
            game[k] = v
        end
    end
    return game
end

function _createPlayerGroup(players)
    return {
        players = players,
        activePlayerIndex = 1,
        nextPlayerIndex = 2,
        step = 1,
        size = function(self)
            return #self.players
        end,
        changePlayer = function(self)
            self.activePlayerIndex = self.nextPlayerIndex
            self.nextPlayerIndex = (self.activePlayerIndex+self.step-1)%self:size() + 1
        end,
        undoChange = function(self)
            self.nextPlayerIndex = self.activePlayerIndex
            self.activePlayerIndex = (self.nextPlayerIndex-self.step-1)%self:size() + 1
        end,
        currentPlayer = function(self)
            return self.players[self.activePlayerIndex]
        end,
        nextPlayer = function(self)
            return self.players[self.nextPlayerIndex]
        end,
        setStep = function(self, step)
            self.step = step
            self.nextPlayerIndex = (self.activePlayerIndex+self.step-1)%self:size() + 1
        end,
        setSequence = function(self, start, step)
            self.activePlayerIndex = start
            self:setStep(step)
        end
    }
end

function createCard(properties, quadTopLeft, x, y)
    card = {
        x = x or 0,
        y = y or 0,
        r = 0,
        sx = 1,
        sy = 1,
        ox = cardDimensions.x/2,
        oy = cardDimensions.y/2,
        quad = love.graphics.newQuad(
            quadTopLeft[1] * cardDimensions.x,
            quadTopLeft[2] * cardDimensions.y,
            unpack(quadFiller)
        ),
        collidesWith = function(self, x, y)
            return (x >= self.x-cardDimensions.x/2 and x <= self.x+cardDimensions.x/2) and
            (y >= self.y-cardDimensions.y/2 and y <= self.y+cardDimensions.y/2)
        end,
        draw = function(self, x, y)
            love.graphics.draw(
                cardsImg,
                self.quad,
                self.x, self.y,
                self.r,
                self.sx, self.sy,
                self.ox, self.oy)
        end,
        drawAt = function(self, x, y, r, sx, sy)
            self.x = x or 0
            self.y = y or 0
            self.r = r or 0
            self.sx = sx or 1
            self.sy = sy or self.sx
        end
    }
    if properties ~= nil then
        for k, v in pairs(properties) do
            card[k] = v
        end
    end
    return card
end

function createHand(x, y, separation, raiseHeight, activeCard)
    return {
        x = x or math.floor(love.graphics.getWidth()/2),
        y = y or math.floor(love.graphics.getHeight() * 5/6),
        cards = {},
        n = 0,
        separation = separation or 140,
        raiseHeight = raiseHeight or 80,
        activeCard = activeCard or 1,
        add = function(self, card)
            if card ~= nil then
                self.n = self.n+1
                self:_refreshDrawLoc('increased')
                table.insert(self.cards, card)
            end
        end,
        remove = function(self, index)
            if self.n > 0 then
                self.n = self.n-1
                self:_refreshDrawLoc('decreased')
                return table.remove(self.cards, index)
            end
        end,
        drawLocs = {},
        draw = function(self)
            for i = 1, #self.cards do
                self.cards[i]:draw()
            end
        end,
        update = function(self)
            for i = 1, #self.cards do
                if self.cards[i]:collidesWith(love.mouse.getPosition()) then
                    self.activeCard = i
                end
            end
            for i = 1, #self.cards do
                if self.activeCard == i then
                    self.cards[i]:drawAt(self.drawLocs[i].x, self.drawLocs[i].y-self.raiseHeight)
                else
                    self.cards[i]:drawAt(self.drawLocs[i].x, self.drawLocs[i].y)
                end
            end
        end,
        getCardSep = function(self, n)
            return math.floor(self.separation * (0.91^(n-1)))
        end,
        _refreshDrawLoc = function(self, growth)
            x = self.x - (self.n-1) * self:getCardSep(self.n) / 2
            self.drawLocs = {}
            for i = 1, self.n do
                table.insert(self.drawLocs, {x = x, y = self.y})
                x = x + self:getCardSep(self.n)
            end
        end
    }
end

function createPile(properties, spread, scale, x, y)
    pile = {
        x = x or math.floor(love.graphics.getWidth()/2),
        y = y or math.floor(love.graphics.getHeight() * 1/3),
        scale = scale or 0.5,
        spread = spread or 50,
        cards = {},
        top,
        add = function(self, card)
            if card ~= nil then
                card.x = self.x + math.random(self.spread)-self.spread/2
                card.y = self.y + math.random(self.spread)-self.spread/2
                card.r = _randomRotation()
                card.sx = self.scale
                card.sy = card.sx
                self.top = card
                self:pilingEffects(card)
                table.insert(self.cards, card)
            end
        end,
        addMultiple = function(self, cards)
            for i = 1, #cards do
                card = cards[i]
                card.x = self.x + math.random(self.spread)-self.spread/2
                card.y = self.y + math.random(self.spread)-self.spread/2
                card.r = _randomRotation()
                card.sx = self.scale
                card.sy = card.sx
                self.top = card
                self:pilingEffects(card)
                table.insert(self.cards, card)
            end
        end,
        remove = function(self, index)
            if index == nil then
                card = table.remove(self.cards)
                card.r, card.sx, card.sx = 0, 1, 1
                if #self.cards > 0 then
                    self.top = self.cards[#self.cards]
                else
                    self.top = nil
                end
                return card
            else
                card = table.remove(self.cards, index)
                card.r, card.sx, card.sx = 0, 1, 1
                if #self.cards > 0 then
                    self.top = self.cards[#self.cards]
                else
                    self.top = nil
                end
                return card
            end
        end,
        draw = function(self)
            for i = 1, #self.cards do
                self.cards[i]:draw()
            end
        end,
        pilingEffects = function(self, card)
            -- More rules
        end,
        canGet = function(self, card)
            -- Rules of the game
        end
    }
    if properties ~= nil then
        for k, v in pairs(properties) do
            pile[k] = v
        end
    end
    return pile
end

function createPlayer(name, properties, hand)
    player = {
        name = name,
        hand = hand or createHand(),
        add = function(self, card)
            self.hand:add(card)
        end,
        currentCard = function(self)
            return self.hand.cards[self.hand.activeCard]
        end,
        draw = function(self)
            love.graphics.printf('Player: ' .. self.name, math.floor(love.graphics.getWidth()* 4/5), math.floor(love.graphics.getHeight()* 1/3), 60, 'center')
            self.hand:draw()
        end,
        update = function(self)
            self.hand:update()
        end
    }
    if properties ~= nil then
        for k,v in pairs(properties) do
            player[k] = v
        end
    end
    return player
end

function createDeck()   -- user defined function, to be generalized more
    deck = {}
    colors = {'red', 'yellow', 'green', 'blue'}
    cards = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'skip', 'reverse', 'draw'}
    for i = 1, #colors do
        for j = 1, #cards do
            table.insert(deck, createCard({suite = colors[i], type = cards[j]}, {(j-1), (i-1)}))
        end
    end
    table.insert(deck, createCard({suite = 'wild', type = 'one'}, {13, 0}))
    table.insert(deck, createCard({suite = 'wild', type = 'one'}, {13, 0}))
    table.insert(deck, createCard({suite = 'wild', type = 'four'}, {13, 4}))
    table.insert(deck, createCard({suite = 'wild', type = 'four'}, {13, 4}))

    return deck
end

function _randomRotation()
    return math.random(360) * math.pi/180
end

function cardPoint(card)
    if card.type == 'draw' or card.type == 'skip' or card.type == 'reverse' then
        return 20
    elseif card.suite == 'wild' then
        return 50
    else
        return tonumber(card.type)
    end
end

function gameOver(player)
    gameState = 'OVER'
    gameOverMessage = game:currentPlayer().name .. ' wins by '
    points = 0
    players = game.playerGroup.players
    for i = 1, #players do
        if i ~= player then
            for j = 1, #players[i].hand.cards do
                points = points + cardPoint(players[i].hand.cards[j])
            end
        end
    end
    gameOverMessage = gameOverMessage .. tostring(points) .. ' points!'
end

function love.load()
    game = createGame({suites = {'red', 'blue', 'green', 'yellow'}})
    game.deck = createDeck()
    game.pile = createPile()
    game:setPlayers({
        createPlayer('A', {suiteChoice = 1}),
        createPlayer('B', {suiteChoice = 2}),
    })

    game.pile.canGet = function(self, card)
        if card.suite == 'wild' then return true end
        if card.suite == self.top.suite or card.type == self.top.type then return true end
        if card.suite == self.suite then return true end
        return false
    end

    game.pile.pilingEffects = function(self, card)
        if game:currentPlayer().hand.n < 1 then
            gameOver(game:getActivePlayerIndex())
        end
        if card.suite == 'wild' then
            self.suite = game.suites[game:currentPlayer().suiteChoice]
            if card.type == 'four' then
                game:nextTurn()
                game:currentPlayer():add(game:randomDraw())
                game:currentPlayer():add(game:randomDraw())
                game:currentPlayer():add(game:randomDraw())
                game:currentPlayer():add(game:randomDraw())
            end
        else
            self.suite = card.suite
        end
        if card.type == 'draw' then
            game:nextTurn()
            game:currentPlayer():add(game:randomDraw())
            game:currentPlayer():add(game:randomDraw())
        elseif card.type == 'skip' then
            game:nextTurn()
        elseif card.type == 'reverse' then
            game:setSequence(game:getActivePlayerIndex(), -game:getStep())
        end
        game:nextTurn()
    end

    game.handSize = 7
    game:preGame()

    game.pile:add(game:randomDrawBetween(1, #game.deck-4))
    game.pile.suite = game.pile.top.suite
end

function love.update(dt)
    game:update()
end

function love.draw()
    if gameState == 'OVER' then
        love.graphics.printf(gameOverMessage, love.graphics.getWidth()/2, 40, 60, 'center')
    end
    game:draw()
    -- love.graphics.print('mousemoved x, y: (' .. gX .. ', ' .. gY .. ')', 300, 120)
    -- love.graphics.print(game.suites[game:currentPlayer().suiteChoice], 300, 80)
    -- love.graphics.print('pile.top.type: ' .. pile.top.type, 300, 60)
    -- love.graphics.print('pile.top.suite: ' .. pile.top.suite, 300, 40)
    -- love.graphics.print('pile.suite: ' .. pile.suite, 300, 100)
    -- love.graphics.print('mouse x, y: (' .. love.mouse.getX() .. ', ' .. love.mouse.getY() .. ')', 300, 20)
end

function love.mousepressed(x, y, button, istouch, presses)
    if gameState ~= 'OVER' then
        currentHand = game:currentPlayer().hand
        if button == 1 and presses == 1 and
        game:currentPlayer():currentCard():collidesWith(x, y) and
        game.pile:canGet(game:currentPlayer():currentCard()) then
            game.pile:add(currentHand:remove(currentHand.activeCard))
        elseif button == 2 then
            game:currentPlayer():add(game:randomDraw())
        elseif presses == 2 then
            game:reshufflePileAsDeckExcept(1)
        end
    end
end

function love.wheelmoved(x, y)
    if y == 1 then
        game:currentPlayer().suiteChoice = (game:currentPlayer().suiteChoice)%#game.suites + 1
    elseif y == -1 then
        game:currentPlayer().suiteChoice = (game:currentPlayer().suiteChoice-2)%#game.suites + 1
    end
end

function love.keypressed(key)
    if key == 'r' then
        game:currentPlayer().suiteChoice = 1
    elseif key == 'b' then
        game:currentPlayer().suiteChoice = 2
    elseif key == 'g' then
        game:currentPlayer().suiteChoice = 3
    elseif key == 'y' then
        game:currentPlayer().suiteChoice = 4
    elseif key == 'd' then
        game:currentPlayer():add(game:randomDraw())
    elseif key == 'w' then
        game:nextTurn()
    elseif key == 's' then
        game:previousTurn()
    elseif key == 'e' then
        game:reshufflePileAsDeckExcept(1)
    elseif key == 'p' then
        love.load()
    end
end
