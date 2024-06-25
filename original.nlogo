globals [
  ; these are setup-only variables, used to make changing the model easier
  min-price
  population
  sales-per-tick
  starting-asking-price
  starting-willing-to-pay
  amount-high
  amount-low

  ; these variables track data as the model runs
  avg-per-buyer
  avg-per-seller
  total-sales
  remaining-supply
  starting-money-actual
]

breed [ shadows shadow ]
breed [ sellers seller ]
breed [ buyers buyer ]
breed [ pops pop ]

turtles-own [
  money        ; keeps track of the amount of money the turtle has
  next-xcor    ; the x-coordinate of the next position
  next-ycor    ; the y-coordinate of the next position
  percent
  my-shadow    ; the shadow of the turtle
]

sellers-own [
  items-for-sale ; the quantity that the seller has to sell
  asking-price
  starting-supply
  behavior-after-sale ; the behavior of seller after a sale
  behavior-no-sale ; the behavior of the seller after a no sale
  sold ; the quantity that the seller has sold
]

buyers-own [
  want-to-buy ; the quantity the buyer wants to buy
  willing-to-pay
  starting-demand
  behavior-after-purchase
  behavior-no-purchase ; the behavior of the buyer after not buying
  bought ; the quantity that the buyer has bought
]

to setup
  clear-all

  ; set the global variables
  set min-price 0.01
  set population 50
  set total-sales 0
  set starting-asking-price 100
  set starting-willing-to-pay 10
  set amount-high 50
  set amount-low 25

  ; now create the sellers
  create-ordered-sellers population [
    forward 8
    set my-shadow nobody
    set money 0
    set items-for-sale get-random-amount supply-distribution supply-amount
    set starting-supply items-for-sale
    set asking-price get-starting-value starting-asking-price
    ; we set the behavior using anonymous procedures to make the usage during the run simple
    ; the behavior depends on the settings of the model
    let mix-behavior ifelse-value seller-behavior = "mix of all" [random 3] [-1]
    ifelse seller-behavior = "normal" or mix-behavior = 0 [
      set behavior-after-sale [         -> change-price 2.5 ]
      set behavior-no-sale    [ hide? -> if (not hide?) [ change-price -2.0 ] ]
    ] [
      ifelse seller-behavior = "desperate" or mix-behavior = 1 [
        set behavior-after-sale [         -> change-price 0.7 ]
        set behavior-no-sale    [ hide? -> if (not hide?) [ change-price -5.0 ] ]
      ] [
        ; "random" or mix-behavior = 2
        set behavior-after-sale [     -> change-price (random 11 - 5)]
        set behavior-no-sale    [     -> change-price (random 11 - 5)]
    ] ]
  ]

  ; now create the buyers
  create-ordered-buyers population [
    forward 13
    facexy 0 0
    set my-shadow nobody
    set want-to-buy get-random-amount demand-distribution demand-amount
    set starting-demand want-to-buy
    set money get-starting-value starting-money
    set willing-to-pay get-starting-value starting-willing-to-pay
    ; we set the behavior using anonymous procedures to make the usage during the run simple
    ; again, the behavior depends on the settings of the model
    let mix-behavior ifelse-value buyer-behavior = "mix of all" [random 3] [-1]
    ifelse buyer-behavior = "normal" or mix-behavior = 0 [
      set behavior-after-purchase [-> change-payment -2.0 ]
      set behavior-no-purchase    [-> change-payment  2.5 ]
    ] [
      ifelse buyer-behavior = "desperate" or mix-behavior = 1 [
        set behavior-after-purchase [-> change-payment -0.5 ]
        set behavior-no-purchase    [-> change-payment  7.5 ]
      ] [
          ; "random"  or mix-behavior = 2
          set behavior-after-purchase [-> change-payment (random 11 - 5)]
          set behavior-no-purchase    [-> change-payment (random 11 - 5)]
      ]
    ]
  ]

  ; create a shadow for all of our turtles
  create-ordered-shadows population [
    set color 2
    ask one-of sellers with [my-shadow = nobody] [ set my-shadow myself ]
  ]
  create-ordered-shadows population [
    set color 2
    ask one-of buyers with [my-shadow = nobody] [ set my-shadow myself ]
  ]

  ; update our tracking variables
  set avg-per-buyer (sum [starting-demand] of buyers) / (count buyers)
  set avg-per-seller (sum [starting-supply] of sellers) / (count sellers)

  ask sellers [
    update-seller-display
    ; seller shadow sizes are set at the start and do not change
    let shadow-size 1 + (items-for-sale / avg-per-seller)
    ask my-shadow [
      move-to myself
      set heading [heading] of myself
      set size shadow-size
    ]
  ]

  ask buyers [ update-buyer-display ]

  set starting-money-actual sum [money] of buyers

  reset-ticks
end

to-report get-random-amount [ dist amount ]
  report ifelse-value dist = "even" [
    1 + random (get-amount amount)
  ] [ ; "concentrated"
    1 + floor random-exponential ((get-amount amount) / 2)
  ]
end

to-report get-amount [ amount ]
  report ifelse-value amount = "high" [
    amount-high
  ] [ ; else "low"
    amount-low
  ]
end

to-report get-starting-value [ starting-value ]
  report precision ((starting-value / 2) + random (starting-value / 2)) 2
end

to go
  if (sum [items-for-sale] of sellers = 0 or (0 = count buyers with [money > 0 and want-to-buy > 0])) [ stop ]

  clear-drawing
  set sales-per-tick 0

  ; move our buyers to their next position in the circle
  ; record the positions first, since if we move before processing all of them, it screws things up
  ask buyers [
    let next ifelse-value who = (1 * population) [(2 * population) - 1] [who - 1]
    set next-xcor [xcor] of buyer next
    set next-ycor [ycor] of buyer next
  ]
  ; okay, now we can move
  ask buyers [
    set xcor next-xcor
    set ycor next-ycor
    facexy 0 0
  ]

  set remaining-supply (sum [items-for-sale] of sellers)

  let offset 1 + ticks mod population
  foreach (range 0 population) [ i ->
    let the-seller seller (population * 0 + i)
    let the-buyer buyer (population * 1 + ((i + offset) mod population))
    ask the-buyer [ do-commerce-with the-seller ]
  ]

  ask buyers [update-buyer-display]
  ask sellers [update-seller-display]
  set total-sales (total-sales + sales-per-tick)

  ask pops [
    ifelse (size < 0.1 or not stars?)
    [ die ]
    [
      set heading (atan (random-float 0.5 - 0.25) 1)
      jump 0.5
      set size size - 0.025
      set color color - 0.25
    ]
  ]

  ; sanity check
  if (any? buyers with [want-to-buy > 0 and willing-to-pay > money]) [ error "Cannot have turtles that want to pay more than their cash!" ]

  tick
end

to update-buyer-display
  if want-to-buy = 0 [
    set color 2
  ]
  set size 1 + (bought / avg-per-buyer)
  let shadow-size 1 + (want-to-buy / avg-per-buyer)
  ask my-shadow [
    move-to myself
    set heading [heading] of myself
    set size shadow-size
  ]
end

to update-seller-display
  if items-for-sale = 0 [ set color 2 ]
  set size 1 + (items-for-sale / avg-per-seller)
end

to do-commerce-with [ the-seller ]
  let asking [asking-price] of the-seller
  ifelse ([items-for-sale] of the-seller > 0 and want-to-buy > 0 and asking <= money and asking <= willing-to-pay) [
    create-link the-seller self yellow

    set sales-per-tick (sales-per-tick + 1)
    set want-to-buy (want-to-buy - 1)
    let price asking
    set money precision (money - price) 2
    set money ifelse-value money < min-price [0] [money]
    set bought (bought + 1)
    ask the-seller [
      set items-for-sale (items-for-sale - 1)
      set money precision (money + price) 2
      set sold (sold + 1)
      run behavior-after-sale
    ]
    run behavior-after-purchase
    create-star
  ] [
    ; else no purchase was made
    create-link the-seller self blue
    let hide? (sellers-ignore-full-buyers? and (want-to-buy = 0))
    ask the-seller [ (run behavior-no-sale hide?) ]
    run behavior-no-purchase
  ]
end

to create-star
  if stars? [
    hatch-pops 1 [
      set color yellow
      set shape "star"
      set size 0.5
      set label ""
    ]
  ]
end

to create-link [ some-seller some-buyer some-color ]
  ask some-seller [
    let oc color
    let x xcor
    let y ycor
    set color some-color
    set pen-size 3
    pen-down
    move-to some-buyer
    pen-up
    setxy x y
    set color oc
  ]
end

to change-price [ change ]
  let before asking-price
  set percent 1 + (change / 100)
  set asking-price check-for-min-price (precision (percent * asking-price) 2)
  if before = asking-price [
    if change < 0 and before != min-price [
      set asking-price precision (asking-price - min-price) 2
    ]
    if change > 0 [
      set asking-price precision (asking-price + min-price) 2
    ]
  ]
end

to change-payment [ change ]
  let before willing-to-pay
  set percent 1 + (change / 100)
  set willing-to-pay check-for-min-price (precision (percent * willing-to-pay) 2)
  if before = willing-to-pay [
    if change < 0 and before != min-price [
      set willing-to-pay precision (willing-to-pay - min-price) 2
    ]
    if change > 0 [
      set willing-to-pay precision (willing-to-pay + min-price) 2
    ]
  ]
  if willing-to-pay > money [ set willing-to-pay money ]
end

to-report seller-cash
  report sum [money] of sellers
end

to-report average-price
  report (ifelse-value total-sales = 0 [ 0.00 ] [ precision (seller-cash / total-sales) 2 ])
end

to-report percent-money-taken
  report 100 * sum [money] of sellers / starting-money-actual
end

to-report percent-items-sold
  report 100 * sum [sold] of sellers / sum [items-for-sale + sold] of sellers
end

to-report percent-demand-satisfied
  report 100 * sum [bought] of buyers / sum [want-to-buy + bought] of buyers
end

to-report check-for-min-price [ value ]
  report precision ifelse-value value < min-price [min-price] [value] 2
end


; Copyright 2017 Uri Wilensky.
; See Info tab for full copyright and license.
