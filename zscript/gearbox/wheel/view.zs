/* Copyright Alexander Kromm (mmaulwurff@gmail.com) 2020-2021
 *
 * This file is part of Gearbox.
 *
 * Gearbox is free software: you can redistribute it and/or modify it under the
 * terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * Gearbox is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * Gearbox.  If not, see <https://www.gnu.org/licenses/>.
 */

class gb_WheelView
{

  static
  gb_WheelView from(gb_Options options, gb_MultiWheelMode multiWheelMode)
  {
    let result = new("gb_WheelView");

    result.setAlpha(1.0);
    result.setBaseColor(0x2222CC);

    result.mScreen  = gb_Screen.from();
    result.mOptions = options;
    result.mMultiWheelMode = multiWheelMode;

    return result;
  }

  void setAlpha(double alpha)
  {
    mAlpha = alpha;
  }

  void setBaseColor(int color)
  {
    mBaseColor = color;
  }

  void display( gb_ViewModel viewModel
              , gb_WheelControllerModel controllerModel
              , bool showPointer
              , int  innerIndex
              , int  outerIndex
              ) const
  {
    drawInnerWheel();

    uint nWeapons = viewModel.tags.size();
    int  radius   = Screen.getHeight() * 5 / 32;
    int  allowedWidth = Screen.getHeight() * 3 / 16 - MARGIN * 2;

    mCenter = mScreen.getWheelCenter();

    if (mMultiWheelMode.isEngaged(viewModel))
    {
      gb_MultiWheelModel multiWheelModel;
      gb_MultiWheel.fill(viewModel, multiWheelModel);

      uint nPlaces = multiWheelModel.data.size();
      for (uint i = 0; i < nPlaces; ++i)
      {
        bool isWeapon = multiWheelModel.isWeapon[i];
        int  data     = multiWheelModel.data[i];

        if (isWeapon) displayWeapon(i, data, nPlaces, radius, allowedWidth, viewModel, mCenter);
        else          displaySlot  (i, data, nPlaces, radius);
      }

      if (innerIndex != UNDEFINED_INDEX)
      {
        drawHands(nPlaces, innerIndex, mCenter, 0);
      }

      if (outerIndex != UNDEFINED_INDEX && !multiWheelModel.isWeapon[innerIndex])
      {
        int slot = multiWheelModel.data[innerIndex];
        drawOuterWeapons( innerIndex
                        , outerIndex
                        , nPlaces
                        , slot
                        , viewModel
                        , radius
                        , allowedWidth
                        , int(controllerModel.radius)
                        );
      }
    }
    else
    {
      for (uint i = 0; i < nWeapons; ++i)
      {
        displayWeapon(i, i, nWeapons, radius, allowedWidth, viewModel, mCenter);
      }

      if (innerIndex != UNDEFINED_INDEX)
      {
        drawHands(nWeapons, innerIndex, mCenter, 0);
      }
    }

    if (showPointer) drawPointer(controllerModel.angle, controllerModel.radius);
  }

// private: ////////////////////////////////////////////////////////////////////////////////////////

  private
  void drawOuterWeapons( int  innerIndex
                       , int  outerIndex
                       , uint nPlaces
                       , int  slot
                       , gb_ViewModel viewModel
                       , int  radius
                       , int  allowedWidth
                       , int  controllerRadius
                       )
  {
    int wheelRadius = gb_Screen.getWheelRadius();
    double angle             = itemAngle(nPlaces, innerIndex);
    double outerWheelCenterX =  sin(angle) * wheelRadius + mCenter.x;
    double outerWheelCenterY = -cos(angle) * wheelRadius + mCenter.y;
    drawOuterWheel(outerWheelCenterX, outerWheelCenterY, -angle);

    uint nWeapons = viewModel.tags.size();

    uint start = 0;
    for (; start < nWeapons && viewModel.slots[start] != slot; ++start);
    uint end = start;
    for (; end < nWeapons && viewModel.slots[end] == slot; ++end);

    uint   nWeaponsInSlot = end - start;
    double startingAngle  = angle - 90 + (180.0 / nWeaponsInSlot / 2);

    uint place = 0;
    for (uint i = start; i < end; ++i, ++place)
    {
      displayWeapon( place
                   , i
                   , nWeaponsInSlot * 2
                   , radius
                   , allowedWidth
                   , viewModel
                   , (outerWheelCenterX, outerWheelCenterY)
                   , startingAngle
                   );
    }

    int deadRadius = gb_Screen.getWheelDeadRadius();
    if (deadRadius > controllerRadius || controllerRadius > wheelRadius)
    {
      drawHands( nWeaponsInSlot * 2
               , outerIndex
               , (outerWheelCenterX, outerWheelCenterY)
               , -startingAngle
               );
    }
  }

  private
  void drawInnerWheel()
  {
    TextureID texture = TexMan.checkForTexture("gb_circ", TexMan.Type_Any);
    int wheelDiameter = gb_Screen.getWheelRadius() * 2;
    Screen.drawTexture( texture
                      , NO_ANIMATION
                      , mCenter.x
                      , mCenter.y
                      , DTA_FillColor    , mBaseColor
                      , DTA_AlphaChannel , true
                      , DTA_Alpha        , mAlpha
                      , DTA_CenterOffset , true
                      , DTA_DestWidth    , wheelDiameter
                      , DTA_DestHeight   , wheelDiameter
                      );
  }

  private
  void drawOuterWheel(double x, double y, double angle)
  {
    TextureID texture = TexMan.checkForTexture("gb_hcir", TexMan.Type_Any);
    int wheelDiameter = gb_Screen.getWheelRadius() * 2;
    Screen.drawTexture( texture
                      , NO_ANIMATION
                      , x
                      , y
                      , DTA_FillColor    , mBaseColor
                      , DTA_AlphaChannel , true
                      , DTA_Alpha        , mAlpha
                      , DTA_CenterOffset , true
                      , DTA_Rotate       , angle
                      , DTA_DestWidth    , wheelDiameter
                      , DTA_DestHeight   , wheelDiameter
                      );
  }

  private
  void displayWeapon( uint place
                    , uint weaponIndex
                    , uint nPlaces
                    , int  radius
                    , int  allowedWidth
                    , gb_ViewModel viewModel
                    , vector2 center
                    , double startingAngle = 0.0
                    )
  {
    double angle = (startingAngle + itemAngle(nPlaces, place)) % 360;

    int x = int(round( sin(angle) * radius + center.x));
    int y = int(round(-cos(angle) * radius + center.y));

    // code is adapted from GZDoom AltHud.DrawImageToBox.
    TextureID weaponTexture = viewModel.icons[weaponIndex];
    Vector2   weaponSize    = TexMan.getScaledSize(weaponTexture) * 2;
    bool      isTall        = (weaponSize.y > weaponSize.x);

    double scale = isTall
      ? ((allowedWidth < weaponSize.y) ? allowedWidth / weaponSize.y : 1.0)
      : ((allowedWidth < weaponSize.x) ? allowedWidth / weaponSize.x : 1.0)
      ;

    scale *= gb_Screen.getScaleFactor();

    int weaponWidth  = int(weaponSize.x * scale);
    int weaponHeight = int(weaponSize.y * scale);

    drawWeapon(weaponTexture, x, y, weaponWidth, weaponHeight, angle, isTall);
  }

  private
  void displaySlot(uint place, int slot, uint nPlaces, int radius)
  {
    double angle = itemAngle(nPlaces, place);

    int x = int(round( sin(angle) * radius + mCenter.x));
    int y = int(round(-cos(angle) * radius + mCenter.y));

    drawText(string.format("%d", slot), x, y);
  }

  private static
  double itemAngle(uint nItems, uint index)
  {
    return 360.0 / nItems * index;
  }

  private
  void drawHands(uint nPlaces, uint selectedIndex, vector2 center, double startAngle)
  {
    if (nPlaces < 2) return;

    double handsAngle = startAngle - itemAngle(nPlaces, selectedIndex);

    TextureID handTexture = TexMan.checkForTexture("gb_hand", TexMan.Type_Any);
    double sectorAngleHalfWidth = 360.0 / 2.0 / nPlaces - 2;

    double baseHeight  = 1080;
    double heightRatio = Screen.getHeight() / baseHeight;
    double baseWidth   = Screen.getWidth() / heightRatio;

    Screen.drawTexture( handTexture
                      , NO_ANIMATION
                      , center.x / heightRatio
                      , center.y / heightRatio
                      , DTA_KeepRatio     , true
                      , DTA_CenterOffset  , true
                      , DTA_Alpha         , mAlpha
                      , DTA_Rotate        , handsAngle - sectorAngleHalfWidth
                      , DTA_VirtualWidth  , int(baseWidth)
                      , DTA_VirtualHeight , int(baseHeight)
                      , DTA_FlipX         , true
                      );

    Screen.drawTexture( handTexture
                      , NO_ANIMATION
                      , center.x / heightRatio
                      , center.y / heightRatio
                      , DTA_KeepRatio     , true
                      , DTA_CenterOffset  , true
                      , DTA_CenterOffset  , true
                      , DTA_Alpha         , mAlpha
                      , DTA_Rotate        , handsAngle + sectorAngleHalfWidth
                      , DTA_VirtualWidth  , int(baseWidth)
                      , DTA_VirtualHeight , int(baseHeight)
                      );
  }

  private
  void drawPointer(double angle, double radius)
  {
    int x = int(round( sin(angle) * radius + mCenter.x));
    int y = int(round(-cos(angle) * radius + mCenter.y));
    TextureID pointerTexture = TexMan.checkForTexture("gb_pntr", TexMan.Type_Any);
    vector2 size = TexMan.getScaledSize(pointerTexture);
    size *= gb_Screen.getScaleFactor();

    Screen.drawTexture( pointerTexture
                      , NO_ANIMATION
                      , x
                      , y
                      , DTA_CenterOffset , true
                      , DTA_Alpha        , mAlpha
                      , DTA_DestWidth    , int(size.x)
                      , DTA_DestHeight   , int(size.y)
                      );
  }

  private
  void drawWeapon(TextureID texture, int x, int y, int w, int h, double angle, bool isTall) const
  {
    bool flipX = (angle > 180);
    if (flipX) angle -= 180;
    angle = -angle + 90;

    if (isTall) angle -= 90;

    Screen.drawTexture( texture
                      , NO_ANIMATION
                      , x
                      , y
                      , DTA_CenterOffset , true
                      , DTA_KeepRatio    , true
                      , DTA_DestWidth    , w
                      , DTA_DestHeight   , h
                      , DTA_Alpha        , mAlpha
                      , DTA_Rotate       , angle
                      , DTA_FlipX        , flipX
                      );

    if (!mOptions.getWheelTint()) return;

    Screen.drawTexture( texture
                      , NO_ANIMATION
                      , x
                      , y
                      , DTA_CenterOffset , true
                      , DTA_KeepRatio    , true
                      , DTA_DestWidth    , w
                      , DTA_DestHeight   , h
                      , DTA_Alpha        , mAlpha * 0.3
                      , DTA_FillColor    , mBaseColor
                      , DTA_Rotate       , angle
                      , DTA_FlipX        , flipX
                      );
  }

  private
  void drawText(string aString, int x, int y)
  {
    int textScale = max(Screen.getHeight() / 360, 1);

    Font aFont = mOptions.getWheelFont() ? smallFont : bigFont;

    x -= aFont.stringWidth(aString) * textScale / 2;
    y -= aFont.getHeight()          * textScale / 2;

    Screen.drawText( aFont
                   , Font.CR_WHITE
                   , x
                   , y
                   , aString
                   , DTA_Alpha  , mAlpha
                   , DTA_ScaleX , textScale
                   , DTA_ScaleY , textScale
                   );
  }

  const NO_ANIMATION = 0; // == false

  const MARGIN = 4;

  const UNDEFINED_INDEX = -1;

  private double  mAlpha;
  private color   mBaseColor;
  private vector2 mCenter;

  private gb_Screen mScreen;
  private gb_Options mOptions;
  private gb_MultiWheelMode mMultiWheelMode;

} // class gb_WheelView