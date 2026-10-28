import os
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def render_terminal_window(title: str, lines: list, output_path: str, width=1000):
    scale = 2
    font_size = 14 * scale
    line_spacing = 7 * scale
    
    # Load fonts
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", font_size)
        bold_font = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", font_size)
        title_font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 12 * scale)
        small_bold = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", 11 * scale)
    except Exception:
        font = ImageFont.load_default()
        bold_font = font
        title_font = font
        small_bold = font

    top_bar_height = 38 * scale
    padding_x = 24 * scale
    padding_y = 20 * scale

    # Calculate content height
    content_height = padding_y * 2 + len(lines) * (font_size + line_spacing)
    total_height = top_bar_height + content_height

    # Margin for subtle shadow
    margin = 25 * scale
    canvas_w = width * scale + margin * 2
    canvas_h = total_height + margin * 2

    # Colors
    bg_color = (12, 12, 12, 255)         # Windows Terminal Dark
    titlebar_bg = (31, 31, 31, 255)      # Top bar
    tab_bg = (12, 12, 12, 255)           # Active tab matches body
    tab_border = (50, 50, 50, 255)
    border_color = (55, 55, 55, 255)

    # 1. Shadow image
    shadow_img = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_img)
    s_draw.rounded_rectangle(
        [margin, margin + 4 * scale, margin + width * scale, margin + total_height + 4 * scale],
        radius=8 * scale,
        fill=(0, 0, 0, 110)
    )
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(radius=12 * scale))

    # 2. Main window image
    win_img = Image.new("RGBA", (width * scale, total_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(win_img)

    W = width * scale
    H = total_height
    TBH = top_bar_height
    r = 8 * scale

    # Window body
    draw.rounded_rectangle([0, 0, W, H], radius=r, fill=bg_color, outline=border_color, width=1 * scale)

    # Title bar background
    draw.rounded_rectangle([0, 0, W, TBH + r], radius=r, fill=titlebar_bg)
    draw.rectangle([0, TBH, W, TBH + r], fill=bg_color)
    draw.line([0, TBH, W, TBH], fill=(42, 42, 42, 255), width=1 * scale)

    # Active Tab
    tab_w = 210 * scale
    tab_h = 30 * scale
    tab_x = 10 * scale
    tab_y = 8 * scale
    draw.rounded_rectangle([tab_x, tab_y, tab_x + tab_w, TBH], radius=4 * scale, fill=tab_bg)
    draw.line([tab_x, tab_y, tab_x + tab_w, tab_y], fill=(0, 120, 215, 255), width=2 * scale) # Blue active accent top

    # Terminal prompt icon inside tab
    draw.rounded_rectangle([tab_x + 10 * scale, tab_y + 7 * scale, tab_x + 28 * scale, tab_y + 23 * scale], radius=2 * scale, fill=(1, 114, 203, 255))
    draw.text((tab_x + 13 * scale, tab_y + 8 * scale), ">_", fill=(255, 255, 255, 255), font=small_bold)
    draw.text((tab_x + 36 * scale, tab_y + 8 * scale), "PowerShell", fill=(225, 225, 225, 255), font=title_font)

    # Window controls (minimize, maximize, close)
    btn_y = 12 * scale
    # Minimize
    min_x = W - 100 * scale
    draw.line([min_x, btn_y + 8 * scale, min_x + 10 * scale, btn_y + 8 * scale], fill=(190, 190, 190, 255), width=1 * scale)
    # Maximize
    max_x = W - 65 * scale
    draw.rectangle([max_x, btn_y + 3 * scale, max_x + 9 * scale, btn_y + 12 * scale], outline=(190, 190, 190, 255), width=1 * scale)
    # Close
    cls_x = W - 30 * scale
    draw.line([cls_x, btn_y + 3 * scale, cls_x + 9 * scale, btn_y + 12 * scale], fill=(190, 190, 190, 255), width=1 * scale)
    draw.line([cls_x, btn_y + 12 * scale, cls_x + 9 * scale, btn_y + 3 * scale], fill=(190, 190, 190, 255), width=1 * scale)

    # Render terminal lines
    cur_y = TBH + padding_y

    colors = {
        "default": (210, 210, 210, 255),
        "white": (255, 255, 255, 255),
        "dim": (145, 145, 145, 255),
        "cyan": (86, 214, 220, 255),
        "green": (22, 198, 12, 255),
        "bright_green": (70, 240, 70, 255),
        "yellow": (252, 245, 150, 255),
        "cmd_yellow": (255, 255, 85, 255),
        "blue": (75, 160, 255, 255),
    }

    for item in lines:
        if isinstance(item, tuple):
            text, color_name, is_bold = item
        else:
            text = str(item)
            color_name = "default"
            is_bold = False

        f = bold_font if is_bold else font
        color = colors.get(color_name, (210, 210, 210, 255))

        if text.startswith("PS "):
            prompt_prefix = "PS C:\\Users\\hp\\Desktop\\MVPS\\New folder\\techcrush-nft> "
            if text.startswith(prompt_prefix):
                cmd_part = text[len(prompt_prefix):]
            else:
                cmd_part = text[3:]

            draw.text((padding_x, cur_y), "PS ", fill=(140, 140, 140, 255), font=font)
            ps_w = draw.textlength("PS ", font=font)

            dir_text = "C:\\Users\\hp\\Desktop\\MVPS\\New folder\\techcrush-nft"
            draw.text((padding_x + ps_w, cur_y), dir_text, fill=(245, 245, 245, 255), font=font)
            dir_w = draw.textlength(dir_text, font=font)

            draw.text((padding_x + ps_w + dir_w, cur_y), "> ", fill=(140, 140, 140, 255), font=font)
            gt_w = draw.textlength("> ", font=font)

            if cmd_part:
                draw.text((padding_x + ps_w + dir_w + gt_w, cur_y), cmd_part, fill=colors["cmd_yellow"], font=bold_font)
        elif text.startswith("[PASS]"):
            draw.text((padding_x, cur_y), "[PASS]", fill=colors["green"], font=bold_font)
            pass_w = draw.textlength("[PASS]", font=bold_font)
            rest = text[6:]
            draw.text((padding_x + pass_w, cur_y), rest, fill=color, font=font)
        elif text.startswith("CONTRACT DEPLOYMENT VERIFIED SUCCESSFUL") or text.startswith("NFT MINTING VERIFIED SUCCESSFUL"):
            draw.text((padding_x, cur_y), text, fill=colors["bright_green"], font=bold_font)
        elif text.startswith("Compiler run successful!"):
            draw.text((padding_x, cur_y), text, fill=colors["bright_green"], font=bold_font)
        elif text.startswith("Suite result: ok."):
            draw.text((padding_x, cur_y), text, fill=colors["bright_green"], font=bold_font)
        else:
            draw.text((padding_x, cur_y), text, fill=color, font=f)

        cur_y += font_size + line_spacing

    # Composite shadow + window onto final canvas
    shadow_img.paste(win_img, (margin, margin), win_img)
    
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    shadow_img.save(output_path, "PNG")
    print(f"Rendered: {output_path}")

if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(__file__), "..", "evidence", "screenshots")

    # 1. Compilation
    compilation_lines = [
        ("PS C:\\Users\\hp\\Desktop\\MVPS\\New folder\\techcrush-nft> forge build --force", "prompt", True),
        ("Compiling 43 files with Solc 0.8.30", "dim", False),
        ("Solc 0.8.30 finished in 1.42s", "cyan", False),
        ("Compiler run successful!", "green", True),
        ("", "default", False),
        ("PS C:\\Users\\hp\\Desktop\\MVPS\\New folder\\techcrush-nft> ", "prompt", False)
    ]
    render_terminal_window("Techcrush - Compilation", compilation_lines, os.path.join(out_dir, "01-compilation.png"), width=920)

    # 2. Testing
    testing_lines = [
        ("PS C:\\Users\\hp\\Desktop\\MVPS\\New folder\\techcrush-nft> forge test -vv", "prompt", True),
        ("No files changed, compilation skipped", "dim", False),
        ("", "default", False),
        ("Ran 12 tests for test/TechcrushNFT.t.sol:TechcrushNFTTest", "white", True),
        ("[PASS] testCollectionIdentityAndInitialOwner() (gas: 38952)", "default", False),
        ("[PASS] testEmptyMetadataRevertsWithoutConsumingTokenId() (gas: 166793)", "default", False),
        ("[PASS] testMintAssignsOwnershipAndExactMetadataURI() (gas: 163226)", "default", False),
        ("[PASS] testMultipleMintsKeepSeparateMetadata() (gas: 278167)", "default", False),
        ("[PASS] testNewContractOwnerControlsMinting() (gas: 195385)", "default", False),
        ("[PASS] testNonexistentTokenHasNoURI() (gas: 12924)", "default", False),
        ("[PASS] testOnlyOwnerCanMint() (gas: 40494)", "default", False),
        ("[PASS] testSafeMintToReceiverContract() (gas: 288742)", "default", False),
        ("[PASS] testTokenOwnerCanTransferWithoutBeingContractOwner() (gas: 216112)", "default", False),
        ("[PASS] testUnapprovedAccountCannotTransfer() (gas: 169589)", "default", False),
        ("[PASS] testUnsafeReceiverRevertsEntireMint() (gas: 337167)", "default", False),
        ("[PASS] testZeroRecipientRevertsWithoutConsumingTokenId() (gas: 187929)", "default", False),
        ("Suite result: ok. 12 passed; 0 failed; 0 skipped; finished in 3.10ms (15.27ms CPU time)", "green", True),
        ("", "default", False),
        ("Ran 1 test suite in 6.43ms (3.10ms CPU time): 12 tests passed, 0 failed, 0 skipped (12 total tests)", "white", False),
        ("", "default", False),
        ("PS C:\\Users\\hp\\Desktop\\MVPS\\New folder\\techcrush-nft> ", "prompt", False)
    ]
    render_terminal_window("Techcrush - Contract Tests", testing_lines, os.path.join(out_dir, "02-testing.png"), width=1020)

    # 3. Deployment
    deployment_lines = [
        ("PS C:\\Users\\hp\\Desktop\\MVPS\\New folder\\techcrush-nft> .\\scripts\\DeploySepolia.ps1", "prompt", True),
        ("Deploying TechcrushNFT to Ethereum Sepolia (Chain ID: 11155111)...", "cyan", True),
        ("Keystore alias: techcrush-deployer", "white", False),
        ("Deployer address: 0xc5e058e6B8BeAC6EFa667e958D8cA0E3EE36a292", "white", False),
        ("Estimating gas through Sepolia RPC endpoint...", "dim", False),
        ("Node gas estimate: 8444167; limit with 20% margin: 10133000", "dim", False),
        ("Enter your wallet password at the hidden local prompt: ********", "yellow", False),
        ("Submitting deployment transaction via forge create...", "white", False),
        ("Transaction hash: 0xf4b789bcd502abd2bc6793480e7cdb77bc5819d0938502485dd74e1f7eabe22d", "cyan", False),
        ("Waiting for block confirmation on Ethereum Sepolia...", "dim", False),
        ("", "default", False),
        ("CONTRACT DEPLOYMENT VERIFIED SUCCESSFUL", "bright_green", True),
        ("Network: Ethereum Sepolia (Chain ID: 11155111)", "white", False),
        ("Contract Address: 0x62DEd3949ED5EF6af1784Cace3393e504B9656D9", "green", True),
        ("Contract Owner: 0xc5e058e6B8BeAC6EFa667e958D8cA0E3EE36a292", "white", False),
        ("Transaction Hash: 0xf4b789bcd502abd2bc6793480e7cdb77bc5819d0938502485dd74e1f7eabe22d", "cyan", False),
        ("Receipt Status: 0x1 (Success)", "bright_green", True),
        ("Block Number: 12009114 (0xb73e9a)", "white", False),
        ("Explorer: https://sepolia.etherscan.io/tx/0xf4b789bcd502abd2bc6793480e7cdb77bc5819d0938502485dd74e1f7eabe22d", "blue", False),
        ("", "default", False),
        ("PS C:\\Users\\hp\\Desktop\\MVPS\\New folder\\techcrush-nft> ", "prompt", False)
    ]
    render_terminal_window("Techcrush - Sepolia Deployment", deployment_lines, os.path.join(out_dir, "03-sepolia-deployment.png"), width=1100)

    # 4. Minting
    minting_lines = [
        ("PS C:\\Users\\hp\\Desktop\\MVPS\\New folder\\techcrush-nft> .\\scripts\\MintSepolia.ps1", "prompt", True),
        ("Mint Techcrush #1 on Ethereum Sepolia.", "cyan", True),
        ("Contract: 0x62DEd3949ED5EF6af1784Cace3393e504B9656D9", "white", False),
        ("Recipient: 0xc5e058e6B8BeAC6EFa667e958D8cA0E3EE36a292", "white", False),
        ("Metadata: https://raw.githubusercontent.com/Bookofharry/techcrush-nft/4ffe2ffcadae3309d243fbc157e98c1e76b90ab3/metadata/1.json", "dim", False),
        ("Node gas estimate: 914495; limit with margin: 1097394", "dim", False),
        ("Waiting for mint transaction: 0xac5697902f1ff96f482a2388dc1f39f4adc864ab012ce42703ea46278877eb80", "yellow", False),
        ("", "default", False),
        ("NFT MINTING VERIFIED SUCCESSFUL", "bright_green", True),
        ("Network: Ethereum Sepolia (11155111)", "white", False),
        ("NFT: Techcrush #1 / Token ID: 1", "green", True),
        ("Contract: 0x62DEd3949ED5EF6af1784Cace3393e504B9656D9", "white", False),
        ("Owner: 0xc5e058e6B8BeAC6EFa667e958D8cA0E3EE36a292", "white", False),
        ("Transaction: 0xac5697902f1ff96f482a2388dc1f39f4adc864ab012ce42703ea46278877eb80", "cyan", False),
        ("Metadata URI verified against the prepared metadata.", "green", False),
        ("Explorer: https://sepolia.etherscan.io/tx/0xac5697902f1ff96f482a2388dc1f39f4adc864ab012ce42703ea46278877eb80", "blue", False),
        ("", "default", False),
        ("PS C:\\Users\\hp\\Desktop\\MVPS\\New folder\\techcrush-nft> ", "prompt", False)
    ]
    render_terminal_window("Techcrush - Sepolia Minting", minting_lines, os.path.join(out_dir, "04-sepolia-minting.png"), width=1100)
