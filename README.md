# 🎰 VertsaSlot - Nilo Brasil

Um projeto para um desafio técnico da VertsaPlay de **máquina caça-níquel** desenvolvido no **Godot Engine 4.5**.  

## ✨ Funcionalidades
- Rolo com movimento contínuo e reciclagem de símbolos.
- Botões **Start** e **Stop**:
  - Start inicia a rotação e desabilita o Stop.
  - Stop desacelera o rolo e define o resultado.
- Timeout de segurança: se o jogador não clicar Stop, o rolo para automaticamente.
- Feedback visual:
  - **CongratsLabel** → quando o jogador vence.
  - **TryAgainLabel** → para os outros casos.
- Feedback sonoro com **VictorySound** e **BackgroundSound**.
- Reinício automático após cada giro.

## 🛠️ Estrutura
```text
Screen 1 - MenuScreen
MenuScreen (TextureRect)
├─ MarginContainer (MarginContainer)
│  └─ GameLabel (Label)    
│  └─ Logo (Sprite2d)
│   └─ HBoxContainer (HBoxContainer)
│     ├─ ButtonPlay
│     └─ ButtonQuit
├─ AudioStreamPlayer (AudioStreamPlayer)

Screen 2 - MainScreen
MainScreen (Control)
├─ Panel (Panel) 
├─ ReelViewport (Control)        ← Janela visível do rolo
│  └─ SlotContainer (Control)    ← Símbolos em movimento
├─ CongratsLabel (Label)
├─ TryAgainLabel (Label)
├─ VictorySound (AudioStreamPlayer)
├─ BackgroundSound (AudioStreamPlayer)
└─ ButtonsContainer (HBoxContainer)
   ├─ ButtonStart
   └─ ButtonStop
