require 'gruff'

# 固定値(機種スペック))
OATARI_RITSU=1/360.to_f.freeze
OATARI_DEDAMA=2000.freeze
KAITENRITSU=20/250.to_f.freeze
KAKUHEN_KEIZOKURITSU=70/100.to_f.freeze

# 固定値(シナリオ)
RAITEN_NISU=100
START_TAMA=10000.freeze
MAX_KAITENSU=10000

#　変数
@verbose = true if ARGV[0] == "verbose"

def verbose(msg)
  puts msg if @verbose
end

def print_if(day, &block)
  if day % (RAITEN_NISU / 10) == 0
    yield if block_given?
  end
end

def hit?(ritsu)
  rand <= ritsu
end

def kakuhen_mode
  renchan = 0
  verbose "***** 確変突入 *****"
  loop do
    break unless hit? KAKUHEN_KEIZOKURITSU
    renchan += 1
    @oatari_cnt += 1
    @current_tama += OATARI_DEDAMA
    verbose " - 大当たり(継続)! #{renchan}連チャン中  計#{@oatari_cnt}回目"
  end
  verbose "***** 確変終了 #{@current_tama} *****"
end

def syukkin(day)
  print_if(day) {puts "○○○○○#{day}日目開始○○○○○"}

  @current_tama = START_TAMA
  @oatari_cnt = 0

  # 実処理
  MAX_KAITENSU.times do |i|

    if hit? KAITENRITSU
      if hit? OATARI_RITSU
        @oatari_cnt += 1 
        verbose "大当たり! #{@oatari_cnt}回目"
        @current_tama += OATARI_DEDAMA
        if hit? KAKUHEN_KEIZOKURITSU
          kakuhen_mode
        else
          verbose "  単発・・・"
        end
      end
    end

    @current_tama -= 1
    break if @current_tama <= 0
  end 
  
  now_syushi = (@current_tama - START_TAMA) * 4
  @syuushi = @syuushi + now_syushi
  @gdata << @syuushi

  print_if(day) do
    puts "○○○○○#{day}日目終了○○○○○"
    puts " - 最終玉数　： #{@current_tama}"
    puts " - 大当り数　： #{@oatari_cnt}"
    puts " - 収支　　　： #{now_syushi}"
    puts " - 総合収支　： #{@syuushi}"
    puts
  end
end

def sampling(g, label)
  @syuushi = 0
  @gdata = []
  RAITEN_NISU.times do |day|
    syukkin day
  end
  g.data label, @gdata
end

#############
# メイン処理
#############
g = Gruff::Line.new
g.title = "Balance of Payments Gruff"
g.maximum_value = 2_000_000
g.minimum_value = -2_000_000

sampling(g, :John)
sampling(g, :Bob)
sampling(g, :Mike)

g.write('gruff-pachinko.png')
puts "Finish Balance of payments Graph"