extends Node2D
class_name CliffGenerator
# Procedurální generátor okrajových útesů.
# Využívá FastNoiseLite pro vytvoření přirozeně "zubatých" okrajů, 
# které jsou ihned převedeny na kolizní polygony a obarveny.

@export var is_right_side: bool = false
@export var base_width: float = 3000.0 # Jak daleko do šířky útes (neviditelně) sahá, zabraňuje vypadnutí
@export var segment_length: float = 180.0 # Vzdálenost bodů na ose Y. Čím nižší, tím detailnější.
@export var jaggedness: float = 200.0 # Jak moc čouhají zuby do úrovně hráče

var scrap_scene: PackedScene = preload("res://scenes/ScrapItem.tscn")

@onready var static_body = StaticBody2D.new()
@onready var poly = Polygon2D.new()
@onready var collision = CollisionPolygon2D.new()
var depth_drawer: Node2D = Node2D.new()

func _ready() -> void:
    # Programové sestavení uzlů tak at neplevelíme manuálně scénu
    add_child(static_body)
    add_child(poly)
    static_body.add_child(collision)
    static_body.add_to_group("cliffs")
    
    # Barva hlubinného kamenného útesu
    poly.color = Color(0.12, 0.15, 0.22) 
    
    # Útesy musí být vykreslovány nad podvodním panelem
    z_index = 20
    
    # Texty s hloubkou se musí vykreslovat pod podvodním panelem i pod ponorkami
    depth_drawer.z_as_relative = false
    depth_drawer.z_index = -1
    depth_drawer.draw.connect(_on_depth_drawer_draw)
    add_child(depth_drawer)

    generate_cliff()
    # spawn_scrap()  # NAHRAZENO PŘES LOOT SPAWNER
    
    pass

func generate_cliff() -> void:
    var points := PackedVector2Array()
    # Camera starts looking down at Y ~ 0, submarine spawns at 300
    # Let's begin the cliff polygon lower down (Y = 300, submarine level)
    # The first segments will be straight down to Y = 800
    var current_y: float = 300.0 
    var max_y: float = GameManager.MAX_GAME_DEPTH * GameManager.PIXELS_PER_METER
    var floor_depth: float = 10.0 * GameManager.PIXELS_PER_METER # 10 metrů tlustá podlaha
    
    var noise = FastNoiseLite.new()
    noise.seed = randi()
    noise.frequency = 0.005
    
    if not is_right_side:
        # ------- LEVÝ ÚTES -------
        points.append(Vector2(-base_width, current_y)) 
        
        # Rovná stěna od ponorky (y=300) dolu (y=800)
        points.append(Vector2(0, current_y))
        points.append(Vector2(0, 800.0))
        
        current_y = 800.0
        
        while current_y <= max_y:
            # abs() zajistí, že zuby rostou "do mapy", nikoliv ven
            var offset = abs(noise.get_noise_1d(current_y)) * jaggedness
            points.append(Vector2(offset, current_y)) 
            current_y += segment_length
            
        # Zastavíme generování přesně na dně (max_y)
        var final_offset = abs(noise.get_noise_1d(max_y)) * jaggedness
        points.append(Vector2(final_offset, max_y)) 
        
        # --- PODLAHA ---
        # Protáhneme pevninu od tohoto posledního bodu směrem do středu mapy o hodně (aby se v půlce potkala s druhou stranou)
        points.append(Vector2(base_width, max_y))
        points.append(Vector2(base_width, max_y + floor_depth))
        
        # A pak ji uzavřeme přes hluboký spodek zpět do původní hrany báze
        points.append(Vector2(-base_width, max_y + floor_depth))
        
    else:
        # ------- PRAVÝ ÚTES -------
        points.append(Vector2(base_width, 300.0)) 
        
        # Rovná stěna od ponorky (y=300) dolu (y=800)
        points.append(Vector2(0, 300.0))
        points.append(Vector2(0, 800.0))
        
        current_y = 800.0
        
        while current_y <= max_y:
            # Přidáme šumovou odchylku (+5000), ať oba útesy nejsou stejné
            var offset = abs(noise.get_noise_1d(current_y + 5000.0)) * jaggedness
            points.append(Vector2(-offset, current_y)) 
            current_y += segment_length
            
        var final_offset = abs(noise.get_noise_1d(max_y + 5000.0)) * jaggedness
        points.append(Vector2(-final_offset, max_y)) 
        
        # --- PODLAHA ---
        # Protáhneme pevninu od tohoto posledního bodu směrem do středu mapy (do levé strany)
        points.append(Vector2(-base_width, max_y))
        points.append(Vector2(-base_width, max_y + floor_depth))
        
        points.append(Vector2(base_width, max_y + floor_depth))
        
    poly.polygon = points
    collision.polygon = points

func _on_depth_drawer_draw() -> void:
    # Vykreslíme značky hloubky každých 100 metrů
    var max_depth_meters: int = int(GameManager.MAX_GAME_DEPTH)
    var pixels_per_meter: float = GameManager.PIXELS_PER_METER
    
    # Použijeme výchozí font systému/Godotu
    var font := ThemeDB.fallback_font
    var font_size := 32
    var color := Color(1, 1, 1, 0.5) # Poloprůhledná bílá
    
    # Kreslit budeme jen od hladiny (Y=0) do maximální hloubky
    # Krok je 100 metrů
    for m in range(100, max_depth_meters, 100):
        # Ponorka startuje s Y v 300 pixelech a bere to za 0m. 
        # Takže k vypočteným pixelům vždy připočítáme 300.0 (viz starting_position lodi)
        var y_pos: float = float(m) * pixels_per_meter + 300.0
        
        # Místo složitého napojování Noise to prostě nakreslíme fixně do prostoru (hráč si to domyslí jako "bojky" atp.)
        # případně do okraje. Skála nikdy nevyčuhuje dál než `jaggedness`. 
        var start_x: float = jaggedness
        
        if not is_right_side:
            # Na levé straně
            depth_drawer.draw_line(Vector2(start_x, y_pos), Vector2(start_x + 300, y_pos), color, 4.0)
            depth_drawer.draw_string(font, Vector2(start_x + 50, y_pos - 10), str(m) + "m", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
        else:
            # Na pravé straně
            depth_drawer.draw_line(Vector2(-start_x, y_pos), Vector2(-start_x - 300, y_pos), color, 4.0)
            depth_drawer.draw_string(font, Vector2(-start_x - 150, y_pos - 10), str(m) + "m", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)



func spawn_scrap() -> void:
    var max_y: float = GameManager.MAX_GAME_DEPTH * GameManager.PIXELS_PER_METER
    var current_y: float = 800.0 # Začneme házet kousek pod ponorkou
    
    # Krok mezi potenciálními looty (např. každých 300 pixelů - cca 3 metry)
    var spawn_step: float = 300.0
    
    while current_y < max_y:
        # 40% šance na spawn bedny v tomto kroku
        if randf() > 0.6:
            var instance = scrap_scene.instantiate()
            
            # Náhodné posunutí vlevo nebo vpravo v rámci volného dálkového prostoru
            var random_offset = randf_range(jaggedness + 50, jaggedness + 400.0)
            
            var target_position = Vector2.ZERO
            if not is_right_side:
                target_position = Vector2(random_offset, current_y)
            else:
                target_position = Vector2(-random_offset, current_y)
                
            instance.position = target_position
            add_child(instance)
            
        current_y += spawn_step
