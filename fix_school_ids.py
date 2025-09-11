import csv
import os

# CSVファイルを読み込み
input_file = 'assets/data/School.csv'
output_file = 'assets/data/School_fixed.csv'

with open(input_file, 'r', encoding='utf-8') as infile:
    reader = csv.reader(infile)
    rows = list(reader)

# ヘッダー行を除いて、IDを1から連番で振り直す
header = rows[0]
data_rows = rows[1:]

# 新しいIDで書き直し
fixed_rows = [header]
for i, row in enumerate(data_rows, 1):
    if len(row) >= 7:  # データが完全な行のみ処理
        new_row = [str(i)] + row[1:]  # IDを新しい連番に変更
        fixed_rows.append(new_row)

# 修正されたファイルを保存
with open(output_file, 'w', encoding='utf-8', newline='') as outfile:
    writer = csv.writer(outfile)
    writer.writerows(fixed_rows)

print(f'修正完了: {len(fixed_rows)-1}校のデータを処理しました')
print(f'元のファイル: {len(rows)-1}行')
print(f'修正後ファイル: {len(fixed_rows)-1}行')

# 最初の10行と最後の10行を表示して確認
print('\n修正後の最初の10行:')
for i, row in enumerate(fixed_rows[:11]):
    print(f'{i}: {row}')

print('\n修正後の最後の10行:')
for i, row in enumerate(fixed_rows[-10:], len(fixed_rows)-10):
    print(f'{i}: {row}')
