# VOTAnalysis20120521.praat
# date: 2012.05.21
# author: Yosuke Igarashi
# note: VOTだけでなくフォルマントや声質の分析ができます。
# -----------------------------

form VOT Analysis
   comment Directory where TextGrid file is:
   sentence directory1 H:\VOTdatabase\sound
   comment Directory where Table file is:
   sentence directory2 H:\VOTdatabase\data
   comment Directory where results are output:
   sentence dir3 H:\VOTdatabase\sound
   comment Name of Table?
   sentence tablename table
   comment Utterance tier?
   integer utt_tier 1
   comment Release tier?
   integer release_tier 2
   comment Voicing tier?
   integer voicing_tier 3
   comment comment tier?
   integer comment_tier 4
   comment segment tier?
   integer seg_tier 5
endform


# 各ファイルがあるディレクトリを指定すること。
# また、テキストグリッドが以下の構造になっているか確認すること。
# 　Utterance tier（発話区間を記述）は第1層（インターバル層）
# 　Release tier（閉鎖の開放の時刻を記述）は第2層（ポイント層）
# 　Voicing tier（発声の開始時刻を記述）は第3層（ポイント層）
# 　Comment tier（コメントを記述）は第4層（ポイント層）
# 　segment tier（分節音を記述）は第5層（ポイント層）



# Infoウィンドウの初期化
clearinfo

# インデックスをつける
index$ = "filename'tab$'start'tab$'end'tab$'speaker'tab$'generation'tab$'sex'tab$'hometown'tab$'prefecture'tab$'country'tab$'major_dialect'tab$'dialect'tab$'misc'tab$'type'tab$'utt'tab$'word'tab$'consonant'tab$'vowel'tab$'voicing'tab$'place'tab$'VOT'tab$'lag'tab$'F1'tab$'F2'tab$'F3'tab$'H1-H2'tab$'H1-A3'tab$'c1_dur'tab$'v1_dur'tab$'c2_dur'tab$'v2_dur'tab$'f0_value'tab$'nasal'tab$'v1_comment'tab$'v2_comment'newline$'"
index$ > 'dir3$'/result.txt
index2$ = "filename'tab$'start'tab$'end'tab$'speaker'tab$'generation'tab$'sex'tab$'dialect'tab$'type'tab$'utt'tab$'word'tab$'consonant'tab$'vowel'tab$'voicing'tab$'place'tab$'VOT'tab$'lag'tab$'F1'tab$'F2'tab$'F3'tab$'H1-H2'tab$'H1-A3'tab$'c1_dur'tab$'v1_dur'tab$'c2_dur'tab$'v2_dur'tab$'f0_value'tab$'nasal'tab$'v1_comment'tab$'v2_comment'newline$'"
index2$ > 'dir3$'/result2.txt

Create Strings as file list... fileList 'directory1$'\*.TextGrid
list = selected("Strings")
speakernum = Get number of strings

# 話者情報のテーブルの読み込み
Read Table from tab-separated file... 'directory2$'\subject_info.txt
subject_list = selected("Table")


for speaker to speakernum
#for speaker to 2
   select list
   textname$ = Get string... 'speaker'

   # テキストグリッドの読み込み
   Read from file... 'directory1$'\'textname$'
   filename$ = selected$("TextGrid")
   textgrid = selected("TextGrid")

#  話者名をファイル名から抽出
   where = rindex (textname$, ".")
   where = where - 2
   speaker$ = left$(filename$, where)
   call subject_info


#  繰り返しもファイル名から抽出
   rep$ = right$(filename$, 1)

   # テーブルの読み込み
   Read Table from tab-separated file... 'directory2$'\'tablename$''rep$'.txt
   table = selected("Table")



   select textgrid
   noftier = Get number of tiers
#  もし層が3つしかなかったら、臨時に第4層にpoint tier「comment」を作成する。
   if noftier = 3
      Insert point tier... 4 comment
   endif
#  もし層が3つしかなかったら、臨時に第5層にpoint tier「misc」を作成する。
   if noftier = 4
      Insert point tier... 5 misc
   endif



   # 音声ファイルの読み込み
   Read from file... 'directory1$'\'filename$'.wav
   sound = selected("Sound")


   # テキストグリッドの選択
   select textgrid

   # Release tierのポイントの数を調べ、その値をnum_of_point変数に代入
   num_of_point = Get number of points... 'release_tier'

   #---------------------------------------
   # Release tierポイントの数だけ繰り返すループ
   for i to num_of_point

      select textgrid

      # Release tierの第i番目のポイントの時刻（閉鎖の開放時刻）を取得し、変数timeに代入
      release_time = Get time of point... 'release_tier' 'i'

      # relese_time（閉鎖の開放時刻）から一番近い時刻を持つvoicing tierのポイントのポイント番号を取得し
      # 変数voicing_indexに代入
      voicing_index = Get nearest index from time... 'voicing_tier' 'release_time'

      # Release tierにあるvoicing_index番目のポイントの時刻（発声開始時刻）を取得し
      # 変数voicing_timeに代入
      voicing_time = Get time of point... 'voicing_tier' 'voicing_index'

      # コメントラベルの取得
      # voicing_time（声帯振動の開始時刻）から一番近い時刻を持つcomment tierのポイントのポイント番号を取得し
      # 変数comment_indexに代入
      comment_index = Get nearest index from time... 'comment_tier' 'voicing_time'

      if comment_index <> 0
         # Voicing tierにあるcomment_index番目のポイントの時刻（発声開始時刻）を取得し
         # 変数comment_timeに代入
         comment_time = Get time of point... 'comment_tier' 'comment_index'
         comment_label$ = Get label of point... 'comment_tier' 'comment_index'

         # コメントラベルのバグチェック
         cv_diff = sqrt((comment_time - voicing_time)^2)
         if cv_diff <> 0 and cv_diff < 0.005 and comment_label$ <> "devoiced"
            pause 'filename$' 'comment_time' 'comment_label$' 他の層のラベルと同期しないコメントがあります。
         endif
         if cv_diff = 0
            nasal_comment_label$ = comment_label$
         else
            nasal_comment_label$ = "none"
         endif
      else
         nasal_comment_label$ = "none"
      endif




      # VOTの計算
      # 1000を掛けることでミリセカンド単位に変換
      vot = ( voicing_time - release_time ) * 1000       

      # short_lagかどうかを判断。
      if vot >=0
         lag = 1
      else
         lag = 0
      endif


      # 発話番号との関連付け

      # Utterance tierにあるインターバルで、release_timeの時刻を含むもののインターバル番号を取得し、
      # 変数utt_intervalに代入
      utt_interval = Get interval at time... 'utt_tier' 'release_time'

      # utt_interval番目のインターバルのラベル（発話番号）を取得し、変数utt_label$に代入
      utt_label$ = Get label of interval... 'utt_tier' 'utt_interval'

      # utt_interva番目のインターバルの開始時刻と終了時刻を求める
      utt_start = Get start point... 'utt_tier' 'utt_interval'
      utt_end = Get end point... 'utt_tier' 'utt_interval'

      # 単語の情報を取得するサブルーチンに飛ぶ
      call word_info

      # 母音を分析するサブルーチンに飛ぶ
      call vowel_analysis


#      # 単語の情報を取得するサブルーチンに飛ぶ
#      call word_info


      # 結果の出力
      result$ = "'filename$''tab$''utt_start''tab$''utt_end''tab$''speaker$''tab$''generation$''tab$''sex$''tab$''hometown$''tab$''prefecture$''tab$''country$''tab$''major_dialect$''tab$''dialect$''tab$''misc$''tab$''type$''tab$''utt_label$''tab$''word$''tab$''consonant$''tab$''vowel$''tab$''voicing$''tab$''place$''tab$''vot''tab$''lag''tab$''f1''tab$''f2''tab$''f3''tab$''h1mnh2''tab$''h1mna3''tab$''c1_dur''tab$''v2_dur''tab$''c2_dur''tab$''v2_dur''tab$''f0_mid''tab$''nasal_comment_label$''tab$''v1_comment_label$''tab$''v2_comment_label$''newline$'"
      result2$ = "'filename$''tab$''utt_start''tab$''utt_end''tab$''speaker$''tab$''generation_eng$''tab$''sex$''tab$''dialect_eng$''tab$''type$''tab$''utt_label$''tab$''word$''tab$''consonant$''tab$''vowel$''tab$''voicing$''tab$''place$''tab$''vot''tab$''lag''tab$''f1''tab$''f2''tab$''f3''tab$''h1mnh2''tab$''h1mna3''tab$''c1_dur''tab$''v2_dur''tab$''c2_dur''tab$''v2_dur''tab$''f0_mid''tab$''nasal_comment_label$''tab$''v1_comment_label$''tab$''v2_comment_label$''newline$'"

      result$ >> 'dir3$'/result.txt
      result2$ >> 'dir3$'/result2.txt

      # 作成したオブジェクトを削除するサブルーチンに飛ぶ
#      call remove

   endfor
   #---------------------------------------

   # テキストグリッドの削除
   select textgrid
   plus table
   plus sound
   Remove
endfor

# -----------------------------------------------
# テーブルを利用して、語形の情報を得るサブルーチン
procedure word_info

   # テーブルを選択
   select table

   # （テーブルにおける）列の名前が"label"であるもので、その値が'utt_label$'であるものの
   # 行番号を取得し、変数row_numに代入
   row_num = Search column... label 'utt_label$'

   # （テーブルにおいて）wordと名づけられた列のrow_num番目の行の値（すなわち語形の情報）を
   # 取得し、変数word$に代入
   word$ = Get value... 'row_num' word

   # （テーブルにおいて）consonantと名づけられた列のrow_num番目の行の値（すなわち語頭の子音の情報）を
   # 取得し、変数consonant$に代入
   consonant$ = Get value... 'row_num' consonant

   # （テーブルにおいて）vowelと名づけられた列のrow_num番目の行の値（すなわち語頭音節の母音の情報）を
   # 取得し、変数vowel$に代入
   vowel$ = Get value... 'row_num' vowel

   # （テーブルにおいて）voicingと名づけられた列のrow_num番目の行の値（すなわち語頭子音の有声無声の情報）を
   # 取得し、変数voicing$に代入
   voicing$ = Get value... 'row_num' voicing

   # （テーブルにおいて）placeと名づけられた列のrow_num番目の行の値（すなわち語頭子音の調音位置の情報）を
   # 取得し、変数place$に代入
   place$ = Get value... 'row_num' place

   # （テーブルにおいて）typeと名づけられた列のrow_num番目の行の値（すなわちデータセットの種類）を
   # 取得し、変数type$に代入
   type$ = Get value... 'row_num' type

endproc






procedure vowel_analysis

   select textgrid
   seg_interval = Get interval at time... 'seg_tier' 'utt_start'

   c1_int = seg_interval + 1
   v1_int = seg_interval + 2
   c2_int = seg_interval + 3
   v2_int = seg_interval + 4

   c1_label$ = Get label of interval... 'seg_tier' 'c1_int'
   v1_label$ = Get label of interval... 'seg_tier' 'v1_int'
   c2_label$ = Get label of interval... 'seg_tier' 'c2_int'
   v2_label$ = Get label of interval... 'seg_tier' 'v2_int'

   if c1_label$ <> "C1"
#      pause 'filename$' 'utt_start' C1と書くべきところに'c1_label$'と書かれています。
   endif
   if v1_label$ <> "V1"
#      pause 'filename$' 'utt_start' V1と書くべきところに'v1_label$'と書かれています。
   endif
   if c2_label$ <> "C2"
#      pause 'filename$' 'utt_start' C2と書くべきところに'c2_label$'と書かれています。
   endif
   if v2_label$ <> "V2"
#      pause 'filename$' 'utt_start' V2と書くべきところに'v2_label$'と書かれています。
   endif

   c1_start = Get start point... 'seg_tier' 'c1_int'
   c1_end = Get end point... 'seg_tier' 'c1_int'
   v1_start = Get start point... 'seg_tier' 'v1_int'
   v1_end = Get end point... 'seg_tier' 'v1_int'
   c2_start = Get start point... 'seg_tier' 'c2_int'
   c2_end = Get end point... 'seg_tier' 'c2_int'
   v2_start = Get start point... 'seg_tier' 'v2_int'
   v2_end = Get end point... 'seg_tier' 'v2_int'

   c1_dur = ( c1_end - c1_start ) * 1000
   v1_dur = ( v1_end - v1_start ) * 1000
   c2_dur = ( c2_end - c2_start ) * 1000
   v2_dur = ( v2_end - v2_start ) * 1000

   # コメントラベルの取得
   # v1_start（V1の開始時刻）から一番近い時刻を持つcomment tierのポイントのポイント番号を取得し
   # 変数comment_indexに代入
   comment_index = Get nearest index from time... 'comment_tier' 'v1_start'
   if comment_index <> 0
      # comment tierにあるcomment_index番目のポイントの時刻（発声開始時刻）を取得し
      # 変数comment_timeに代入
      comment_time = Get time of point... 'comment_tier' 'comment_index'
      comment_label$ = Get label of point... 'comment_tier' 'comment_index'

      # コメントラベルのバグチェック
      cv_diff = sqrt((comment_time - v1_start)^2)
      if cv_diff <> 0 and cv_diff < 0.005 and comment_label$ <> "nasal" and comment_label$ <> "?"
         pause 'filename$' 'comment_time' 'comment_label$' 他の層のラベルと同期しないコメントがあります。'cv_diff'
      endif
      if cv_diff = 0
         v1_comment_label$ = comment_label$
      else
         v1_comment_label$ = "none"
      endif
   else
      v1_comment_label$ = "none"
   endif
   # コメントラベルの取得
   # v1_end（V1の終了時刻）から一番近い時刻を持つcomment tierのポイントのポイント番号を取得し
   # 変数comment_indexに代入
   comment_index = Get nearest index from time... 'comment_tier' 'v1_end'
   if comment_index <> 0
      # comment tierにあるcomment_index番目のポイントの時刻（発声開始時刻）を取得し
      # 変数comment_timeに代入
      comment_time = Get time of point... 'comment_tier' 'comment_index'
      comment_label$ = Get label of point... 'comment_tier' 'comment_index'

      # コメントラベルのバグチェック
      cv_diff = sqrt((comment_time - v1_end)^2)
      if cv_diff <> 0 and cv_diff < 0.005 and comment_label$ <> "nasal" and comment_label$ <> "?"
         pause 'filename$' 'comment_time' 'comment_label$' 他の層のラベルと同期しないコメントがあります。'cv_diff'
      endif
      if cv_diff = 0
         v1_comment_label$ = comment_label$
      else
         v1_comment_label$ = "none"
      endif
   else
      v1_comment_label$ = "none"
   endif



   # コメントラベルの取得
   # v2_start（v2の開始時刻）から一番近い時刻を持つcomment tierのポイントのポイント番号を取得し
   # 変数comment_indexに代入
   comment_index = Get nearest index from time... 'comment_tier' 'v2_start'
   if comment_index <> 0
      # comment tierにあるcomment_index番目のポイントの時刻（発声開始時刻）を取得し
      # 変数comment_timeに代入
      comment_time = Get time of point... 'comment_tier' 'comment_index'
      comment_label$ = Get label of point... 'comment_tier' 'comment_index'

      # コメントラベルのバグチェック
      cv_diff = sqrt((comment_time - v2_start)^2)
      if cv_diff <> 0 and cv_diff < 0.005 and comment_label$ <> "nasal" and comment_label$ <> "?"
         pause 'filename$' 'comment_time' 'comment_label$' 他の層のラベルと同期しないコメントがあります。'cv_diff'
      endif
      if cv_diff = 0
         v2_comment_label$ = comment_label$
      else
         v2_comment_label$ = "none"
      endif
   else
      v2_comment_label$ = "none"
   endif
   # コメントラベルの取得
   # v2_end（v2の終了時刻）から一番近い時刻を持つcomment tierのポイントのポイント番号を取得し
   # 変数comment_indexに代入
   comment_index = Get nearest index from time... 'comment_tier' 'v2_end'
   if comment_index <> 0
      # comment tierにあるcomment_index番目のポイントの時刻（発声開始時刻）を取得し
      # 変数comment_timeに代入
      comment_time = Get time of point... 'comment_tier' 'comment_index'
      comment_label$ = Get label of point... 'comment_tier' 'comment_index'

      # コメントラベルのバグチェック
      cv_diff = sqrt((comment_time - v2_end)^2)
      if cv_diff <> 0 and cv_diff < 0.005 and comment_label$ <> "nasal" and comment_label$ <> "?"
         pause 'filename$' 'comment_time' 'comment_label$' 他の層のラベルと同期しないコメントがあります。 'cv_diff'
      endif
      if cv_diff = 0
         v2_comment_label$ = comment_label$
      else
         v2_comment_label$ = "none"
      endif
   else
      v2_comment_label$ = "none"
   endif

   if v1_comment_label$ = "none" 

      # 母音を切り出すサブルーチンに飛ぶ
      call cut_vowel

      # フォルマント周波数を計測するサブルーチンに飛ぶ
      call formant

      # 声質を計測するサブルーチンに飛ぶ
      call voice_quality

      call remove

   else
      f1 = undefined
      f2 = undefined
      f3 = undefined
      h1mnh2 = undefined
      h1mna3 = undefined
   endif


endproc





procedure cut_vowel
   select textgrid

   vowel_start = v1_start
   vowel_end = v1_end

   vowel_start = vowel_start - 0.05
   vowel_end = vowel_end + 0.05

   vowel_mid = ( vowel_end - vowel_start ) / 2



   select sound
   Extract part... 'vowel_start' 'vowel_end' Hamming 1 no
   shortsound1 = selected("Sound")
   Resample... 16000 50
   shortsound2 = selected("Sound")
   select shortsound1
   Remove

endproc


procedure formant


   if sex$ = "M"
      if vowel = "o"
         maxf = 4000
         f1ref = 500
         f2ref = 900
         f3ref = 2475
      else
         maxf = 5000
         f1ref = 500
         f2ref = 1485
         f3ref = 2475
      endif

   else
      maxf = 5500
      f1ref = 550
      f2ref = 1650
      f3ref = 2750
   endif

   f4ref = 3850
   f5ref = 4950

   select 'shortsound2'
   To Formant (burg)... 0 5 'maxf' 0.025 50
   formant1 = selected("Formant")
#   Track... 3 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 1 1 1
#   formant2 = selected("Formant")

#   select formant2
   select formant1
   f1 = Get value at time... 1 'vowel_mid' Hertz Linear
   f2 = Get value at time... 2 'vowel_mid' Hertz Linear
   f3 = Get value at time... 3 'vowel_mid' Hertz Linear

   if vowel$ = "o" and sex$ = "m" and f2 > 1500
      printline 'filename$' f1 'f1' f2 'f2'
   endif

   select formant1
   Remove
#   select formant2
#   Remove



endproc


procedure voice_quality

   if sex$ = "M"
      max_pitch = 250
   else
      max_pitch = 400
   endif

   select shortsound2
   To Pitch... 0 60 'max_pitch'
   pitch = selected("Pitch")

   Interpolate
   pitch_interpolated = selected("Pitch")

   select 'pitch_interpolated'
   f0_mid = Get value at time... 'vowel_mid' Hertz Linear

   select 'shortsound2'
   To Spectrum (fft)
   spectrum = selected("Spectrum")
   To Ltas (1-to-1)
   ltas = selected("Ltas")


   if f0_mid <> undefined


      rn_f0_mid = round('f0_mid')
      p10_f0_mid = 'f0_mid' / 10


      select 'ltas'
      lowerbh1 = 'f0_mid' - 'p10_f0_mid'
      upperbh1 = 'f0_mid' + 'p10_f0_mid'
      lowerbh2 = 'f0_mid' * 2 - 'p10_f0_mid' * 2
      upperbh2 = 'f0_mid' * 2 + 'p10_f0_mid' * 2

      h1db = Get maximum... 'lowerbh1' 'upperbh1' None
      h1hz = Get frequency of maximum... 'lowerbh1' 'upperbh1' None
      h2db = Get maximum... 'lowerbh2' 'upperbh2' None
      h2hz = Get frequency of maximum... 'lowerbh2' 'upperbh2' None
      rh1hz = round('h1hz')
      rh2hz = round('h2hz')

      p10_f1 = 'f1' / 10
      p10_f2 = 'f2' / 10
      p10_f3 = 'f3' / 10

      lowerba1 = 'f1' - 'p10_f1'
      upperba1 = 'f1' + 'p10_f1'
      lowerba2 = 'f2' - 'p10_f2'
      upperba2 = 'f2' + 'p10_f2'
      lowerba3 = 'f3' - 'p10_f3'
      upperba3 = 'f3' + 'p10_f3'

      a1db = Get maximum... 'lowerba1' 'upperba1' None
      a1hz = Get frequency of maximum... 'lowerba1' 'upperba1' None
      a2db = Get maximum... 'lowerba2' 'upperba2' None
      a2hz = Get frequency of maximum... 'lowerba2' 'upperba2' None
      a3db = Get maximum... 'lowerba3' 'upperba3' None
      a3hz = Get frequency of maximum... 'lowerba3' 'upperba3' None


      h1mnh2 = 'h1db' - 'h2db'
      h1mna1 = 'h1db' - 'a1db'
      h1mna2 = 'h1db' - 'a2db'
      h1mna3 = 'h1db' - 'a3db'
      rh1mnh2 = round('h1mnh2')
      rh1mna1 = round('h1mna1')
      rh1mna2 = round('h1mna2')
      rh1mna3 = round('h1mna3')

   else
      h1mnh2 = undefined
      h1mna3 = undefined
      v1_comment_label$ = "too_short"
   endif



endproc

procedure remove

   select shortsound2
#   plus formant
   plus spectrum
#   plus lpc
   plus ltas
   plus pitch
   plus pitch_interpolated
   Remove
endproc



# -----------------------------------------------
# テーブルを利用して、語形の情報を得るサブルーチン
procedure subject_info

   # テーブルを選択
   select subject_list

   # （テーブルにおける）列の名前が"ID"であるもので、その値が'speaker$'であるものの
   # 行番号を取得し、変数row_numに代入
   row_num = Search column... ID 'speaker$'

   # （テーブルにおいて）"録音日時"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数date$に代入
   date$ = Get value... 'row_num' 録音日時
   row_num = Search column... ID 'speaker$'

   # （テーブルにおいて）"生年月日"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数birth$に代入
   birth$ = Get value... 'row_num' 生年月日

   # （テーブルにおいて）"世代"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数generation$に代入
   generation$ = Get value... 'row_num' 世代

   # （テーブルにおいて）"generation"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数generation_eng$に代入
   generation_eng$ = Get value... 'row_num' generation

   # （テーブルにおいて）"性別"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数sex$に代入
   sex$ = Get value... 'row_num' 性別

   # （テーブルにおいて）"出身"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数hometown$に代入
   hometown$ = Get value... 'row_num' 出身

   # （テーブルにおいて）"都道府県"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数prefecture$に代入
   prefecture$ = Get value... 'row_num' 都道府県

   # （テーブルにおいて）"大分類"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数major_dialect$に代入
   major_dialect$ = Get value... 'row_num' 大分類

   # （テーブルにおいて）"旧国名"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数country$に代入
   country$ = Get value... 'row_num' 旧国名

   # （テーブルにおいて）"方言"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数dialect$に代入
   dialect$ = Get value... 'row_num' 方言

   # （テーブルにおいて）"dialect"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数dialect_eng$に代入
   dialect_eng$ = Get value... 'row_num' dialect

   # （テーブルにおいて）"備考"と名づけられた列のrow_num番目の行の値を
   # 取得し、変数misc$に代入
   misc$ = Get value... 'row_num' 備考




endproc


