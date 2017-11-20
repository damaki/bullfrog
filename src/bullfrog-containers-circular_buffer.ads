------------------------------------------------------------------------------
--                      Copyright (C) 2016 - Present                        --
--                            Jeremiah Breeden                              --
--                           All Rights Reserved                            --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING and COPYING.RUNTIME respectively.  If not, see    --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file might be   --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

-- This package creates a Circular Buffer (FIFO) of a specified item type.
-- The package is meant to be used by creating a shared object of Buffer_Type
-- and using the Consumer package and Producer package to retrieve and add
-- items.  Producer actions are task safe relative to Consumer actions and
-- vice versa.  This package assumes only one producer and one consumer.
generic

   -- Type that the Circular Buffer will hold at each index.
   type Item_Type is private;

package Bullfrog.Containers.Circular_Buffer is

   pragma Pure;

   --*************************************************************************--
   --************************* Buffer Implementation *************************--
   --*************************************************************************--

   -- This type must be modular and atomic for the implementation
   type Buffer_Index is mod 2**32;

   -- This type defines the acceptable values for Buffer_Type.Buffer_Size
   subtype Buffer_Size
      is Buffer_Index range 1 .. Buffer_Index'Last;

   -- This type is meant to be a shared memory space between a consumer
   -- and a producer
   type Buffer

      -- This discriminant defines the usable size of the buffer
      (Max_Size  : Buffer_Size)

   is tagged limited private;

   -----------------------------------------------------------------------------
   -- Returns True if the buffer is empty and False otherwise
   -----------------------------------------------------------------------------
   function Is_Empty (Self : Buffer) return Boolean;

   -----------------------------------------------------------------------------
   -- Returns True if the buffer is not empty and False otherwise
   -----------------------------------------------------------------------------
   function Not_Empty(Self : Buffer) return Boolean;

   -----------------------------------------------------------------------------
   -- Returns True if the buffer is full and False otherwise
   -----------------------------------------------------------------------------
   function Is_Full  (Self : Buffer) return Boolean;

   -----------------------------------------------------------------------------
   -- Returns True if the buffer is not full and False otherwise
   -----------------------------------------------------------------------------
   function Not_Full (Self : Buffer) return Boolean;



   --*************************************************************************--
   --************************ Consumer Implementation ************************--
   --*************************************************************************--

   -- Package used to retrieve items from a buffer.
   package Consumer is

      --------------------------------------------------------------------------
      -- Returns the oldest item from the buffer.  Raises Container_Empty if
      -- there are no items to return.  Note that the buffer's copy of the item
      -- may only calls Finalize when the buffer is leaves scope or a new item
      -- is added to the same physical location as the one retrieved.
      --------------------------------------------------------------------------
      function  Get(Source : in out Buffer) return Item_Type;

      --------------------------------------------------------------------------
      -- Returns the oldest item from the buffer.  Returns False if there are
      -- no items to return and True if successful.  Note that the buffer's
      -- copy of the item may only call Finalize when the buffer is leaves
      -- scope or a new item is added to the same physical location as the one
      -- retrieved.
      --------------------------------------------------------------------------
      function  Get
         (Source : in out Buffer;
          Value  :    out Item_Type)
          return Boolean;

      --------------------------------------------------------------------------
      -- Returns the oldest item from the buffer.  Raises Container_Empty if
      -- there are no items to return.  Note that the buffer's copy of the item
      -- may only calls Finalize when the buffer is leaves scope or a new item
      -- is added to the same physical location as the one retrieved.
      --------------------------------------------------------------------------
      procedure Get(Source : in out Buffer; Value : out Item_Type);

      --------------------------------------------------------------------------
      -- Resets to buffer to be empty.  Note that the buffer's copy of the
      -- items may only call Finalize when the buffer is leaves scope or new
      -- items are added to the same physical location as the ones retrieved.
      --------------------------------------------------------------------------
      procedure Reset(Target : in out Buffer);

   end Consumer;


   --*************************************************************************--
   --************************ Producer Implementation ************************--
   --*************************************************************************--

   -- Package used to add items to a buffer
   package Producer is

      --------------------------------------------------------------------------
      -- Puts a new item on the buffer.  Returns True if successful or False
      -- if there was no room.
      --------------------------------------------------------------------------
      function Put
         (Target : in out Buffer;
          Value  : in     Item_Type)
          return Boolean;

      --------------------------------------------------------------------------
      -- Puts a new item on the buffer.  Raises Container_Full if there is no
      -- room to put the item.
      --------------------------------------------------------------------------
      procedure Put
         (Target : in out Buffer;
          Value  : in     Item_Type);

   end Producer;

private

   -- Type of the actual data array held by a buffer
   type Item_Array is array(Buffer_Index range <>) of Item_Type;

   type Buffer
      (Max_Size  : Buffer_Size)
   is tagged limited record

      -- Actual Data in the buffer.  Needs to be volatile
      Data : Item_Array(0..Max_Size); pragma Volatile(Data);

      -- Index used exclusively by a producer to add elements to the buffer
      -- This needs to be Atomic.
      Put_Index : Buffer_Index := 0; pragma Atomic(Put_Index);

      -- Index used exclusively by a consumer to remove elements from
      -- the buffer.  This needs to be Atomic.
      Get_Index : Buffer_Index := 0; pragma Atomic(Get_Index);

   end record;

end Bullfrog.Containers.Circular_Buffer;
