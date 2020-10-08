/* Copyright Alexander Kromm (mmaulwurff@gmail.com) 2020
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

class gb_Activity
{

  enum Activity
  {

    None,
    WeaponMenu,
    InventoryMenu,

  } // enum gb_Activity

  static
  gb_Activity from()
  {
    let result = new("gb_Activity");
    result.mActivity = gb_Activity.None;
    return result;
  }

  int getActivity() const
  {
    return mActivity;
  }

  void toggleWeaponMenu()
  {
    switch (mActivity)
    {
    case gb_Activity.InventoryMenu:
    case gb_Activity.None:       mActivity = gb_Activity.WeaponMenu; break;
    case gb_Activity.WeaponMenu: mActivity = gb_Activity.None; break;
    }
  }

// private: ////////////////////////////////////////////////////////////////////////////////////////

  private int mActivity;

} // class gb_Activity