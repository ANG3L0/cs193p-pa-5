//
//  SettingsTableViewController.swift
//  Breakout
//
//  Created by Angelo Wong on 3/23/16.
//  Copyright © 2016 Stanford. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var redBlocksEnable: UISwitch!
    
    @IBOutlet weak var numRowsSlider: UISlider!
    
    @IBOutlet weak var difficultyCtl: UISegmentedControl!
    
    @IBOutlet weak var drunkCtl: UISegmentedControl!
    
    private var defaults = NSUserDefaults.standardUserDefaults()
    
    struct Settings {
        static let Red = "Red Blocks Enable in Breakout Game"
        static let Rows = "Number of Rows in Breakout Game"
        static let Difficulty = "Max ball speed and proportion of red balls"
        static let Drunk = "Randomness in Ball Movement"
    }
    private struct Difficulty {
        static let Easy = 0
        static let Medium = 1
        static let Hard = 2
        static let BeastMode = 3
    }
    private struct DrunkLevel {
        static let Sober = 0
        static let Drunk = 1
        static let DUI = 2
    }
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initSettings()
    }
    
    override func viewWillDisappear(animated: Bool) {
        saveSettings()
    }
    
    //MARK: - Helper methods for setting state
    private func saveSettings() {
        defaults.setObject(redBlocksEnable.on, forKey: Settings.Red)
        defaults.setObject(numRowsSlider.value, forKey: Settings.Rows)
        defaults.setObject(difficultyCtl.selectedSegmentIndex, forKey: Settings.Difficulty)
        defaults.setObject(drunkCtl.selectedSegmentIndex, forKey: Settings.Drunk)
    }
    
    private func initSettings() {
        if let redEnabled = defaults.objectForKey(Settings.Red) {
            redBlocksEnable.setOn(redEnabled as! Bool, animated: true)
        } else {
            redBlocksEnable.setOn(true, animated: true)
        }
        if let numRows = defaults.objectForKey(Settings.Rows) {
            numRowsSlider.setValue(numRows as! Float, animated: true)
        } else {
            numRowsSlider.setValue(0.5, animated: true)
        }
        if let difficulty = defaults.objectForKey(Settings.Difficulty) {
            difficultyCtl.selectedSegmentIndex = difficulty as! Int
        } else {
            difficultyCtl.selectedSegmentIndex = Difficulty.Easy
        }
        if let drunk = defaults.objectForKey(Settings.Drunk) {
            drunkCtl.selectedSegmentIndex = drunk as! Int
        } else {
            drunkCtl.selectedSegmentIndex = DrunkLevel.Sober
        }
    }

    // MARK: - Table view data source

//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
