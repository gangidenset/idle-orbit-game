# アート生成プロンプト（フラット）

基地の画像を画像AI（ChatGPT / Gemini など）で作るためのプロンプト全42件。ファイル名と配置先は [ART.md](ART.md) を参照。

## 使い方

1. **見本を1枚作る**：ChatGPT か Gemini で新しい会話を開き、下の「スタイル見本」を貼って生成します。気に入るまで作り直してください。
2. **同じ会話で続けて作る**：気に入った見本ができたら、**同じ会話のまま**各プロンプトを貼ります。どのプロンプトも先頭で見本と同じ絵柄にするよう指示しているので、42枚の絵柄がそろいます。
3. **背景透過を確認する**：建物・惑星・装飾は背景を透明にする必要があります。背景付きで出たら「背景を透過したPNGにしてください」と頼んでください。
4. **ファイル名を付けて送る**：保存した画像に、各カードのファイル名（例: `facility_ore_mine_t1.png`）を付けて送ってください。ゲームに組み込みます。一部だけでも反映できます。

## スタイル見本（最初に1回）

```text
Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Create a style reference sheet for this game: on one image, show a small flat planet, three small buildings of increasing size (a hut, a factory, a tall tower with a light beam) and a small moon, all on a deep navy background. This image will be used as the style reference for all following images.
```

## 背景（5枚）

惑星ごとの宇宙の背景。いちばん奥に表示されます。

### `bg_terra_nova.png` — 背景：始まりの惑星 テラノヴァ

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: an outer space background for the planet "terra_nova", calm blue and indigo, faint teal nebula shapes, large soft geometric nebula shapes, small dot stars in two sizes. Accent color #4FA3E0.

Square 1080x1080, opaque. Keep the lower center calm and darker (a planet will be drawn there). No planets, no spaceships, no text.
```

### `bg_glacies.png` — 背景：氷結惑星 グラシエ

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: an outer space background for the planet "glacies", cold cyan and pale blue, crisp small stars, a few faint ice-crystal sparkles, large soft geometric nebula shapes, small dot stars in two sizes. Accent color #9EE7F5.

Square 1080x1080, opaque. Keep the lower center calm and darker (a planet will be drawn there). No planets, no spaceships, no text.
```

### `bg_dunebell.png` — 背景：砂漠惑星 デューンベル

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: an outer space background for the planet "dunebell", warm amber and dusty orange nebula shapes over navy, large soft geometric nebula shapes, small dot stars in two sizes. Accent color #E3B261.

Square 1080x1080, opaque. Keep the lower center calm and darker (a planet will be drawn there). No planets, no spaceships, no text.
```

### `bg_vulcara.png` — 背景：火山惑星 ヴァルカラ

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: an outer space background for the planet "vulcara", deep red and orange nebula shapes over very dark navy, a few ember-like dots, large soft geometric nebula shapes, small dot stars in two sizes. Accent color #F26B3A.

Square 1080x1080, opaque. Keep the lower center calm and darker (a planet will be drawn there). No planets, no spaceships, no text.
```

### `bg_unknown.png` — 背景：未知の惑星

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: an outer space background for the planet "unknown", violet and magenta nebula shapes, a few unusual geometric star patterns, large soft geometric nebula shapes, small dot stars in two sizes. Accent color #B07CFF.

Square 1080x1080, opaque. Keep the lower center calm and darker (a planet will be drawn there). No planets, no spaceships, no text.
```

## 惑星（5枚）

惑星の本体。円形で背景透過。

### `planet_terra_nova.png` — 惑星：始まりの惑星 テラノヴァ

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a fictional planet seen from space (not Earth), a calm rocky world with blue seas and soft green-teal land masses drawn as simple horizontal band shapes. Big simple shapes so it reads at small size. Main color #4FA3E0.

Perfect circle, centered, filling 95% of the image. Lighter crescent on the top-left edge, darker on the bottom-right. Transparent background, 1024x1024 PNG.
```

### `planet_glacies.png` — 惑星：氷結惑星 グラシエ

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a fictional planet seen from space (not Earth), an icy world with pale cyan and white ice sheets, a few angular glacier shapes and thin crack lines. Big simple shapes so it reads at small size. Main color #9EE7F5.

Perfect circle, centered, filling 95% of the image. Lighter crescent on the top-left edge, darker on the bottom-right. Transparent background, 1024x1024 PNG.
```

### `planet_dunebell.png` — 惑星：砂漠惑星 デューンベル

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a fictional planet seen from space (not Earth), a desert world with sand-gold dunes drawn as wavy horizontal bands and a few rust-orange canyon lines. Big simple shapes so it reads at small size. Main color #E3B261.

Perfect circle, centered, filling 95% of the image. Lighter crescent on the top-left edge, darker on the bottom-right. Transparent background, 1024x1024 PNG.
```

### `planet_vulcara.png` — 惑星：火山惑星 ヴァルカラ

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a fictional planet seen from space (not Earth), a volcanic world with dark basalt surface and glowing orange-red lava rivers as simple flat lines. Big simple shapes so it reads at small size. Main color #F26B3A.

Perfect circle, centered, filling 95% of the image. Lighter crescent on the top-left edge, darker on the bottom-right. Transparent background, 1024x1024 PNG.
```

### `planet_unknown.png` — 惑星：未知の惑星

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a fictional planet seen from space (not Earth), a mysterious world with violet surface, softly glowing geometric patterns and a faint ring of light. Big simple shapes so it reads at small size. Main color #B07CFF.

Perfect circle, centered, filling 95% of the image. Lighter crescent on the top-left edge, darker on the bottom-right. Transparent background, 1024x1024 PNG.
```

## 鉱石採掘施設（6枚）

主役の色：砂金色。1段階目から6段階目へ、だんだん大きく豪華に。同じ会話の中で続けて作ると統一感が出ます。（取り込み済み。作り直す場合のみ）

### `facility_ore_mine_t1.png` — 採掘リグ（1段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a small mining hut with a little drill bit on top — a mining facility that drills ore from the ground on a small planet base. Tier 1 of 6: small and humble, a single simple block, one or two small windows. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sandy gold #D9B38C. Roofs, main walls and panels are sandy gold, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_ore_mine_t2.png` — 採掘プラント（2段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a mining plant with a conveyor belt and an ore hopper — a mining facility that drills ore from the ground on a small planet base. Tier 2 of 6: larger main block with a smaller side module attached on each side, a row of lit windows. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sandy gold #D9B38C. Roofs, main walls and panels are sandy gold, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_ore_mine_t3.png` — 深層掘削基地（3段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a deep drilling base with a large drill tower — a mining facility that drills ore from the ground on a small planet base. Tier 3 of 6: taller, a rounded dome top and a thin antenna with a small red beacon light. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sandy gold #D9B38C. Roofs, main walls and panels are sandy gold, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_ore_mine_t4.png` — 大陸掘削要塞（4段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a continental drilling fortress with heavy armored walls — a mining facility that drills ore from the ground on a small planet base. Tier 4 of 6: tall and impressive, many lit windows, a thin vertical beam of light rising from the top. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sandy gold #D9B38C. Roofs, main walls and panels are sandy gold, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_ore_mine_t5.png` — 惑星コア採掘場（5段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a planet-core excavation complex with a giant drill shaft — a mining facility that drills ore from the ground on a small planet base. Tier 5 of 6: very tall spire, a flat ring orbiting around its middle, a vertical light beam on top. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sandy gold #D9B38C. Roofs, main walls and panels are sandy gold, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_ore_mine_t6.png` — 次元採掘ゲート（6段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a dimensional mining gate, a tall portal frame pulling glowing ore from another dimension — a mining facility that drills ore from the ground on a small planet base. Tier 6 of 6: monumental megastructure, a glowing circular halo behind it, rings and a light beam, the most majestic of all tiers. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sandy gold #D9B38C. Roofs, main walls and panels are sandy gold, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

## エネルギー発電施設（6枚）

主役の色：明るい黄色。1段階目から6段階目へ、だんだん大きく豪華に。同じ会話の中で続けて作ると統一感が出ます。

### `facility_power_plant_t1.png` — ソーラーパネル（1段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a small tilted solar panel on a short post — a power station that generates energy on a small planet base. Tier 1 of 6: small and humble, a single simple block, one or two small windows. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sunny yellow #FFD54F. Roofs, main walls and panels are sunny yellow, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_power_plant_t2.png` — 発電ステーション（2段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a power station with several solar panels and a transformer box — a power station that generates energy on a small planet base. Tier 2 of 6: larger main block with a smaller side module attached on each side, a row of lit windows. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sunny yellow #FFD54F. Roofs, main walls and panels are sunny yellow, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_power_plant_t3.png` — フュージョン炉（3段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a fusion reactor with a domed containment building — a power station that generates energy on a small planet base. Tier 3 of 6: taller, a rounded dome top and a thin antenna with a small red beacon light. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sunny yellow #FFD54F. Roofs, main walls and panels are sunny yellow, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_power_plant_t4.png` — 恒星集光タワー（4段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a stellar concentrator tower with mirror petals around a central tower — a power station that generates energy on a small planet base. Tier 4 of 6: tall and impressive, many lit windows, a thin vertical beam of light rising from the top. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sunny yellow #FFD54F. Roofs, main walls and panels are sunny yellow, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_power_plant_t5.png` — ダイソン・アレイ（5段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a Dyson array, a tall tower with ring-shaped collectors — a power station that generates energy on a small planet base. Tier 5 of 6: very tall spire, a flat ring orbiting around its middle, a vertical light beam on top. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sunny yellow #FFD54F. Roofs, main walls and panels are sunny yellow, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_power_plant_t6.png` — 星核リアクター（6段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a star-core reactor, a monumental tower holding a small bright sun in a cradle — a power station that generates energy on a small planet base. Tier 6 of 6: monumental megastructure, a glowing circular halo behind it, rings and a light beam, the most majestic of all tiers. Amber window lights.

COLOR RULE (most important): the dominant color of this building is sunny yellow #FFD54F. Roofs, main walls and panels are sunny yellow, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

## 合金精錬施設（6枚）

主役の色：青緑（ティール）。1段階目から6段階目へ、だんだん大きく豪華に。同じ会話の中で続けて作ると統一感が出ます。

### `facility_alloy_smelter_t1.png` — 小型炉（1段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a small furnace with a short chimney — a smelter that turns ore into alloy on a small planet base. Tier 1 of 6: small and humble, a single simple block, one or two small windows. Amber window lights.

COLOR RULE (most important): the dominant color of this building is aqua teal (clearly greener than royal blue) #80DEEA. Roofs, main walls and panels are aqua teal (clearly greener than royal blue), covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_alloy_smelter_t2.png` — 精錬工場（2段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a smelting factory with two chimneys and a crucible — a smelter that turns ore into alloy on a small planet base. Tier 2 of 6: larger main block with a smaller side module attached on each side, a row of lit windows. Amber window lights.

COLOR RULE (most important): the dominant color of this building is aqua teal (clearly greener than royal blue) #80DEEA. Roofs, main walls and panels are aqua teal (clearly greener than royal blue), covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_alloy_smelter_t3.png` — プラズマ溶鉱炉（3段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a plasma blast furnace with a glowing cyan core window — a smelter that turns ore into alloy on a small planet base. Tier 3 of 6: taller, a rounded dome top and a thin antenna with a small red beacon light. Amber window lights.

COLOR RULE (most important): the dominant color of this building is aqua teal (clearly greener than royal blue) #80DEEA. Roofs, main walls and panels are aqua teal (clearly greener than royal blue), covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_alloy_smelter_t4.png` — 重合金コンビナート（4段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a heavy alloy industrial complex with stacked furnaces and pipes — a smelter that turns ore into alloy on a small planet base. Tier 4 of 6: tall and impressive, many lit windows, a thin vertical beam of light rising from the top. Amber window lights.

COLOR RULE (most important): the dominant color of this building is aqua teal (clearly greener than royal blue) #80DEEA. Roofs, main walls and panels are aqua teal (clearly greener than royal blue), covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_alloy_smelter_t5.png` — ナノ精錬プラント（5段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a nano-refining plant, a sleek tower with glowing cyan conduits — a smelter that turns ore into alloy on a small planet base. Tier 5 of 6: very tall spire, a flat ring orbiting around its middle, a vertical light beam on top. Amber window lights.

COLOR RULE (most important): the dominant color of this building is aqua teal (clearly greener than royal blue) #80DEEA. Roofs, main walls and panels are aqua teal (clearly greener than royal blue), covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_alloy_smelter_t6.png` — 物質変換炉（6段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a matter conversion reactor, a crystal-like tower transforming light into metal — a smelter that turns ore into alloy on a small planet base. Tier 6 of 6: monumental megastructure, a glowing circular halo behind it, rings and a light beam, the most majestic of all tiers. Amber window lights.

COLOR RULE (most important): the dominant color of this building is aqua teal (clearly greener than royal blue) #80DEEA. Roofs, main walls and panels are aqua teal (clearly greener than royal blue), covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

## 研究施設（6枚）

主役の色：ラベンダー（薄紫）。1段階目から6段階目へ、だんだん大きく豪華に。同じ会話の中で続けて作ると統一感が出ます。

### `facility_research_lab_t1.png` — 観測小屋（1段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a small observation hut with a tiny telescope — a research lab that produces research points on a small planet base. Tier 1 of 6: small and humble, a single simple block, one or two small windows. Amber window lights.

COLOR RULE (most important): the dominant color of this building is lavender purple #CE93D8. Roofs, main walls and panels are lavender purple, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_research_lab_t2.png` — 研究所（2段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a research institute with a satellite dish — a research lab that produces research points on a small planet base. Tier 2 of 6: larger main block with a smaller side module attached on each side, a row of lit windows. Amber window lights.

COLOR RULE (most important): the dominant color of this building is lavender purple #CE93D8. Roofs, main walls and panels are lavender purple, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_research_lab_t3.png` — 量子ラボ（3段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a quantum lab with a glowing lavender dome — a research lab that produces research points on a small planet base. Tier 3 of 6: taller, a rounded dome top and a thin antenna with a small red beacon light. Amber window lights.

COLOR RULE (most important): the dominant color of this building is lavender purple #CE93D8. Roofs, main walls and panels are lavender purple, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_research_lab_t4.png` — 星系アカデミー（4段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a stellar academy with a large observatory dome and pillars — a research lab that produces research points on a small planet base. Tier 4 of 6: tall and impressive, many lit windows, a thin vertical beam of light rising from the top. Amber window lights.

COLOR RULE (most important): the dominant color of this building is lavender purple #CE93D8. Roofs, main walls and panels are lavender purple, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_research_lab_t5.png` — 超知性コア（5段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a super-intelligence core, a tall tower with a glowing lavender brain-like sphere — a research lab that produces research points on a small planet base. Tier 5 of 6: very tall spire, a flat ring orbiting around its middle, a vertical light beam on top. Amber window lights.

COLOR RULE (most important): the dominant color of this building is lavender purple #CE93D8. Roofs, main walls and panels are lavender purple, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_research_lab_t6.png` — 宇宙図書館（6段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a cosmic library, a monumental spire of floating book-like panels — a research lab that produces research points on a small planet base. Tier 6 of 6: monumental megastructure, a glowing circular halo behind it, rings and a light beam, the most majestic of all tiers. Amber window lights.

COLOR RULE (most important): the dominant color of this building is lavender purple #CE93D8. Roofs, main walls and panels are lavender purple, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

## 資源保管施設（6枚）

主役の色：鋼のグレー。1段階目から6段階目へ、だんだん大きく豪華に。同じ会話の中で続けて作ると統一感が出ます。

### `facility_storage_t1.png` — 資材テント（1段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a small supply tent with crates — a storage that keeps resources on a small planet base. Tier 1 of 6: small and humble, a single simple block, one or two small windows. Amber window lights.

COLOR RULE (most important): the dominant color of this building is steel grey #90A4AE. Roofs, main walls and panels are steel grey, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_storage_t2.png` — 倉庫（2段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a warehouse with a large sliding door — a storage that keeps resources on a small planet base. Tier 2 of 6: larger main block with a smaller side module attached on each side, a row of lit windows. Amber window lights.

COLOR RULE (most important): the dominant color of this building is steel grey #90A4AE. Roofs, main walls and panels are steel grey, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_storage_t3.png` — 大型サイロ（3段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a large silo with a domed roof — a storage that keeps resources on a small planet base. Tier 3 of 6: taller, a rounded dome top and a thin antenna with a small red beacon light. Amber window lights.

COLOR RULE (most important): the dominant color of this building is steel grey #90A4AE. Roofs, main walls and panels are steel grey, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_storage_t4.png` — 地下保管網（4段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: an underground storage network entrance with a large hatch and cargo lift — a storage that keeps resources on a small planet base. Tier 4 of 6: tall and impressive, many lit windows, a thin vertical beam of light rising from the top. Amber window lights.

COLOR RULE (most important): the dominant color of this building is steel grey #90A4AE. Roofs, main walls and panels are steel grey, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_storage_t5.png` — 圧縮貯蔵庫（5段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a compression vault, a tall cylinder with ring bands — a storage that keeps resources on a small planet base. Tier 5 of 6: very tall spire, a flat ring orbiting around its middle, a vertical light beam on top. Amber window lights.

COLOR RULE (most important): the dominant color of this building is steel grey #90A4AE. Roofs, main walls and panels are steel grey, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

### `facility_storage_t6.png` — 亜空間ストレージ（6段階目）

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: a subspace storage, a monumental vault door floating in a ring of light — a storage that keeps resources on a small planet base. Tier 6 of 6: monumental megastructure, a glowing circular halo behind it, rings and a light beam, the most majestic of all tiers. Amber window lights.

COLOR RULE (most important): the dominant color of this building is steel grey #90A4AE. Roofs, main walls and panels are steel grey, covering more than half of the building's visible surface. Use navy and blue only for the hexagonal base plate and shadows; white only as small trim. Do not make the building mostly blue.

It must stay readable when shown very small (about 60 pixels tall): bold simple silhouette, a few large shapes, strong contrast between roof/top and body, no tiny details, no thin lines, no small text-like patterns. Compact, sturdy proportions about as wide as tall; tall towers get a wide base. The base plate touches the bottom center of the image and the building fills about 90% of the image height. Light beams and glows are semi-transparent on the transparent background, never blended into a background color. Transparent background, 512x512 PNG.
```

## 装飾（2枚）

惑星のまわりに浮かぶ装飾。

### `deco_moon.png` — 衛星ルナ

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: A small grey moon, flat vector, a few simple circular craters in a darker grey, lighter on the top-left edge.

Readable when shown very small: bold simple shapes, no tiny details. Transparent background, 512x512 PNG, centered.
```

### `deco_station.png` — 軌道ステーション

```text
Use exactly the same art style as the style reference image earlier in this conversation.

Flat vector illustration for a mobile idle game, minimal geometric shapes, limited palette of deep navy, cyan, amber and soft white plus the accent color given below, flat shading with only one light tone and one dark tone per color, light coming from the top-left, clean modern design, no outlines, no gradients except very subtle ones, no text, no watermark. Signature details of this game: buildings are drawn in a slight three-quarter (isometric) view, each building stands on a small hexagonal navy-blue base plate, and each has one warm amber light.

Subject: A small orbital space station, flat vector: a central round hub, a ring around it, and two cyan solar panel wings on the left and right, a tiny amber light in the center.

Readable when shown very small: bold simple shapes, no tiny details. Transparent background, 512x512 PNG, centered.
```
