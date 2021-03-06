/*
 * Copyright (c) 2017-2019 José Amuedo (https://github.com/spheras)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * @class
 * Desktop Folder Settings
 */
public class DesktopFolder.FolderSettings : PositionSettings {
    private string _name;
    public string name {
        get {
            return _name;
        }
        set {
            if (_name != value) {
                _name = value; flagChanged = true;
            }
        }
    }
    private string _bgcolor;
    public string bgcolor {
        get {
            return _bgcolor;
        }
        set {
            if (_bgcolor != value) {
                _bgcolor = value; flagChanged = true;
            }
        }
    }
    private string _fgcolor;
    public string fgcolor {
        get {
            return _fgcolor;
        }
        set {
            if (_fgcolor != value) {
                _fgcolor = value; flagChanged = true;
            }
        }
    }
    private bool _textbold;
    public bool textbold {
        get {
            return _textbold;
        }
        set {
            if (_textbold != value) {
                _textbold = value; flagChanged = true;
            }
        }
    }
    private bool _textshadow;
    public bool textshadow {
        get {
            return _textshadow;
        }
        set {
            if (_textshadow != value) {
                _textshadow = value; flagChanged = true;
            }
        }
    }
    private bool _lockitems;
    public bool lockitems {
        get {
            return _lockitems;
        }
        set {
            if (_lockitems != value) {
                _lockitems = value; flagChanged = true;
            }
        }
    }
    private bool _lockpanel;
    public bool lockpanel {
        get {
            return _lockpanel;
        }
        set {
            if (_lockpanel != value) {
                _lockpanel = value; flagChanged = true;
            }
        }
    }
    private bool _align_to_grid;
    public bool align_to_grid {
        get {
            return _align_to_grid;
        }
        set {
            if (_align_to_grid != value) {
                _align_to_grid = value; flagChanged = true;
            }
        }
    }
    private string[] _items = new string[0];
    public string[] items {
        get {
            return _items;
        }

        set {
            bool different = false;

            if ((value == null && _items != null) || (_items == null && value != null) || value.length != _items.length) {
                different = true;
            }
            if (!different && _items != null) {
                for (int i = 0; i < _items.length; i++) {
                    if (_items[i] != value[i]) {
                        different = true;
                        break;
                    }
                }
            }

            if (different) {
                _items = value; flagChanged = true;
            }
        }
    }

    // util value to know the settings versions
    private int _version;
    public int version {
        get {
            return _version;
        }
        set {
            if (_version != value) {
                _version = value; flagChanged = true;
            }
        }
    }
    // default json seralization implementation only support primitive types

    private File file;

    /**
     * @Constructor
     * @param string name the name of the folder
     */
    public FolderSettings (string name) {
        this.reset ();
    }

    /**
     * @name reset
     * @description reset the properties
     */
    public void reset () {
        this.x             = 100;
        this.y             = 100;
        this.w             = 300;
        this.h             = 300;
        this.bgcolor       = "df_black";
        this.fgcolor       = "df_light";
        this.textbold      = true;
        this.textshadow    = true;
        this.align_to_grid = false;
        this.lockitems     = false;
        this.lockpanel     = false;
        this.name          = name;
        this.items         = new string[0];
        this.version       = DesktopFolder.SETTINGS_VERSION;
        check_off_screen ();
    }

    /**
     * @name build_cell_structure
     * @description build an array describing the cell structure inside the panel.
     * This map is useful to try to structure and align all the items inside the panel
     * @return {ItemSettings[,]} multiarray[rows][cols] with the ItemSettings inside, null are empty places
     */
    public ItemSettings[, ] build_cell_structure () {
        // first, we parse all the items we have so far
        List <ItemSettings> all = new List <ItemSettings> ();
        for (int i = 0; i < this.items.length; i++) {
            ItemSettings is = ItemSettings.parse (this.items[i]);
            all.append (is);
        }

        // we create a cell structure of allowed items
        ItemSettings[, ] cells = new ItemSettings[this.w / DesktopFolder.ICON_DEFAULT_WIDTH, this.h / DesktopFolder.ICON_DEFAULT_WIDTH];

        // now, ordering current items in the structure to see gaps
        for (int i = 0; i < all.length (); i++) {
            ItemSettings item = all.nth_data (i);
            cells[(int) (item.x / DesktopFolder.ICON_DEFAULT_WIDTH), (int) (item.y / DesktopFolder.ICON_DEFAULT_WIDTH)] = item;
        }

        return cells;
    }

    /**
     * @name get_next_gap
     * @description find a gap inside the current structure and put there the item
     * @param {ItemSettings[,]} cell_structure the current cell structure to search gaps (obtained from build_cell_structure)
     * @param {ItemSettings} item the item we want to put inside the current structure, we need to find a gap there
     * @return {Gdk.Point} the point where it was inserted
     */
    public Gdk.Point get_next_gap (ItemSettings[, ] cell_structure, ItemSettings item) {
        for (int row = 0; row < cell_structure.length[0]; row++) {
            for (int col = 0; col < cell_structure.length[1]; col++) {
                if (cell_structure[row, col] == null) {
                    cell_structure[row, col] = item;
                    Gdk.Point point = Gdk.Point ();
                    point.y = row * DesktopFolder.ICON_DEFAULT_WIDTH;
                    point.x = col * DesktopFolder.ICON_DEFAULT_WIDTH;
                    return point;
                }
            }
        }

        return Gdk.Point ();
    }

    /**
     * @name set_item
     * @description replace the current settings for a certain item with other new info
     * @param ItemSettings item the new settings for the item with the same name
     */
    public void set_item (ItemSettings item) {
        // first, we create the list of itemsettings, and replace the old with the new one content
        List <ItemSettings> all = new List <ItemSettings> ();
        for (int i = 0; i < this.items.length; i++) {
            ItemSettings is = ItemSettings.parse (this.items[i]);
            if (is.name == item.name) {
                is = item;
            }
            all.append (is);
        }

        // finally, we recreate the string[]
        string[] str_result = new string[all.length ()];
        for (int i = 0; i < all.length (); i++) {
            ItemSettings element = all.nth_data (i);
            var          str     = element.to_string ();
            str_result[i] = str;
        }
        this.items = str_result;
    }

    /**
     * @name rename
     * @description rename an item on this folder.
     * @param oldName string the old name of the item
     * @param newName string the new name of the item
     */
    public void rename (string oldName, string newName) {
        // first, we create the list of itemsettings, and replace the old with the new one content
        List <ItemSettings> all = new List <ItemSettings> ();
        for (int i = 0; i < this.items.length; i++) {
            ItemSettings is = ItemSettings.parse (this.items[i]);
            if (is.name == oldName) {
                is.name = newName;
            }
            all.append (is);
        }

        // finally, we recreate the string[]
        string[] str_result = new string[all.length ()];
        for (int i = 0; i < all.length (); i++) {
            ItemSettings element = all.nth_data (i);
            var          str     = element.to_string ();
            str_result[i] = str;
        }
        this.items = str_result;
    }

    /**
     * @name add_item
     * @description add an item setting to the list of items of this folder settings
     * @param item ItemSettings the ItemSettings to be added
     */
    public void add_item (ItemSettings item) {
        int length = this.items.length;
        // i don't know why this can't compile
        // this.items.resize(length+1);
        // this.items[this.items.length-1]=item.to_string();

        // alternative, copying it manually?!! :(
        string[] citems = new string[length + 1];
        for (int i = 0; i < length; i++) {
            citems[i] = this.items[i];
        }
        citems[length] = item.to_string ();
        this.items     = citems;
    }

    /**
     * @name get_item
     * @description get an ItemSettings of an existent item inside this folder
     * @param name string the name to find the item
     * @return ItemSettings the ItemSettings found
     */
    public ItemSettings get_item (string name) {
        for (int i = 0; i < this.items.length; i++) {
            ItemSettings is = ItemSettings.parse (this.items[i]);
            if (is.name == name) {
                return is;
            }
        }
        return (ItemSettings) null;
    }

    /**
     * @name save
     * @description persist the changes to the filesystem. The File is the same as the saved initially.
     */
    public void save () {
        this.save_to_file (this.file);
    }

    /**
     * @name save_to_file
     * @description persist the changes to the filesystem. The file used is passed to the function, and saved for following saves.
     * @param file File the file to be saved
     */
    public void save_to_file (File file) {
        if (!flagChanged) {
            return;
        } else {
            // debug ("saving settings!!");
        }

        flagChanged = false;
        this.file   = file;

        store_resolution_position ();

        // string data = Json.gobject_to_data (this, null);
        Json.Node root = Json.gobject_serialize (this);

        // To string: (see gobject_to_data)
        Json.Generator generator = new Json.Generator ();
        generator.set_root (root);
        string data              = generator.to_data (null);
        // debug ("the json generated is:\n%s\n", data);
        try {
            // an output file in the current working directory
            if (file.query_exists ()) {
                file.delete ();
            }

            // creating a file and a DataOutputStream to the file
            /*
                Use BufferedOutputStream to increase write speed:
                var dos = new DataOutputStream (new BufferedOutputStream.sized (file.create (FileCreateFlags.REPLACE_DESTINATION), 65536));
             */
            var dos = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));
            // writing a short string to the stream
            dos.put_string (data);

        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }

    /**
     * @name read_settings
     * @description read the settings from a file to create a Folder Settings object
     * @param file File the file where the settings are persisted
     * @param name string the name of the folder
     * @return FolderSettings the FolderSettings created
     */
    public static FolderSettings read_settings (File file, string name) {
        FolderSettings result = _read_settings (file, name);
        if (result == null) {
            // some error occurred, lets delete the settings and create again
            try {
                file.trash ();
            } catch (Error e) {
            }
            FolderSettings new_folder_settings = new FolderSettings (name);
            new_folder_settings.save_to_file (file);
            return _read_settings (file, name);
        }
        return result;
    }

    private static FolderSettings _read_settings (File file, string name) {
        try {
            string content = "";
            var    dis     = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                content = content + line;
            }
            FolderSettings existent = Json.gobject_from_data (typeof (FolderSettings), content) as FolderSettings;
            existent.file = file;
            existent.name = name;

            // regression for classes, now must have a df_ prefix
            if (existent.bgcolor.length > 0 && !existent.bgcolor.has_prefix ("df_")) {
                if (!existent.bgcolor.has_prefix ("rgb")) {
                    existent.bgcolor = "df_" + existent.bgcolor;
                }
            }
            if (existent.fgcolor.length > 0 && !existent.fgcolor.has_prefix ("df_")) {
                existent.fgcolor = "df_" + existent.fgcolor;
            }

            // regression for on top and back
            if (existent.version == 0) {
                existent.version = DesktopFolder.SETTINGS_VERSION;
            }

            // the properties have not changed, just loaded
            existent.flagChanged = false;

            // after flag changed to false because the check could modify some properties
            existent.check_all ();

            return existent;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return (FolderSettings) null;
        }
    }

    /**
     * @name check_all
     * @description check if all the items described exists fisically, and fixes problems
     */
    public void check_all () {
        List <ItemSettings> all = new List <ItemSettings> ();
        for (int i = 0; i < this.items.length; i++) {
            ItemSettings is = ItemSettings.parse (this.items[i]);
            var basePath = Environment.get_home_dir () + "/Desktop/" + this.name;
            var filepath = basePath + "/" + is.name;
            // debug("checking:"+filepath);
            File f       = File.new_for_path (filepath);
            if (f.query_exists ()) {
                all.append (is);
            } else {
                debug ("Alert! does not exist: %s", filepath);
                // doesn't exist, we must remove the entry
            }
        }

        // finally, we recreate the string[]
        string[] str_result = new string[all.length ()];
        for (int i = 0; i < all.length (); i++) {
            ItemSettings element = all.nth_data (i);
            var          str     = element.to_string ();
            str_result[i] = str;
        }
        this.items = str_result;

        // and we finally resave it
        this.save ();
    }

}
