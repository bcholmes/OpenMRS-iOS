//
//  PatientViewController.m
//  
//
//  Created by Parker Erway on 12/1/14.
//
//

#import "PatientViewController.h"
#import "OpenMRSAPIManager.h"
#import "PatientEncounterListView.h"
#import "PatientVisitListView.h"
#import "MRSObservation.h"
#import "MRSVitalSigns.h"
#import "AddVisitNoteTableViewController.h"
#import "CaptureVitalsTableViewController.h"

@implementation PatientViewController
-(void)setPatient:(MRSPatient *)patient
{
    _patient = patient;
    
    self.information = @[@{@"Name" : patient.name}];
    
    [self.tableView reloadData];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateWithDetailedInfo];
}
-(void)updateWithDetailedInfo
{
    [OpenMRSAPIManager getDetailedDataOnPatient:self.patient completion:^(NSError *error, MRSPatient *detailedPatient) {
        if (error == nil)
        {
            self.patient = detailedPatient;
            self.information = @[@{@"Name" : [self notNil:self.patient.name]},
                                 @{@"Age" : [self notNil:self.patient.age]},
                                 @{@"Gender" : [self notNil:self.patient.gender]},
                                 @{@"Address" : [self formatPatientAdress:self.patient]}];
            
            [self.patient isInCoreData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                self.title = self.patient.name;
            });
        }
    }];
    [OpenMRSAPIManager getVitalsForPatient:self.patient completion:^(NSError *error, NSArray *vitalSigns) {
        NSLog(@"Vital signs request completed. %@", (error ? @"Error encountered" : @""));
        if (error == nil) {
            self.vitalSigns = vitalSigns;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        } else {
            self.vitalSignsError = YES;
        }
    }];
    [OpenMRSAPIManager getEncountersForPatient:self.patient completion:^(NSError *error, NSArray *encounters) {
        if (error == nil)
        {
            self.encounters = encounters;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }];
    [OpenMRSAPIManager getVisitsForPatient:self.patient completion:^(NSError *error, NSArray *visits) {
       if (error == nil)
       {
           self.visits = visits;
           dispatch_async(dispatch_get_main_queue(), ^{
               [self.tableView reloadData];
           });
       }
    }];
}
-(id)notNil:(id)thing
{
    if (thing == nil || thing == [NSNull null])
    {
        return @"";
    }
    return thing;
}
-(NSString *)formatPatientAdress:(MRSPatient *)patient
{
    NSString *string = [self notNil:patient.address1];
    if (![[self notNil:patient.address2] isEqual:@""])
    {
        string = [string stringByAppendingString:[NSString stringWithFormat:@"\n%@", patient.address2]];
    }
    if (![[self notNil:patient.address3] isEqual:@""])
    {
        string = [string stringByAppendingString:[NSString stringWithFormat:@"\n%@", patient.address3]];
    }
    if (![[self notNil:patient.address4] isEqual:@""])
    {
        string = [string stringByAppendingString:[NSString stringWithFormat:@"\n%@", patient.address4]];
    }
    if (![[self notNil:patient.address5] isEqual:@""])
    {
        string = [string stringByAppendingString:[NSString stringWithFormat:@"\n%@", patient.address5]];
    }
    if (![[self notNil:patient.address6] isEqual:@""])
    {
        string = [string stringByAppendingString:[NSString stringWithFormat:@"\n%@", patient.address6]];
    }
    if (![[self notNil:patient.cityVillage] isEqual:@""])
    {
        string = [string stringByAppendingString:[NSString stringWithFormat:@"\n%@", patient.cityVillage]];
    }
    if (![[self notNil:patient.stateProvince] isEqual:@""])
    {
        string = [string stringByAppendingString:[NSString stringWithFormat:@"\n%@", patient.stateProvince]];
    }
    if (![[self notNil:patient.country] isEqual:@""])
    {
        string = [string stringByAppendingString:[NSString stringWithFormat:@"\n%@", patient.country]];
    }
    if (![[self notNil:patient.postalCode] isEqual:@""])
    {
        string = [string stringByAppendingString:[NSString stringWithFormat:@"\n%@", patient.postalCode]];
    }
    return string;
}
-(NSString *)formatDate:(NSString *)date
{
    if (date == nil)
    {
        return @"";
    }
    
    NSDateFormatter *stringToDateFormatter = [[NSDateFormatter alloc] init];
    [stringToDateFormatter setDateFormat:@"Y-MM-dd'T'HH:mm:ss.SSS-Z"];
    NSDate *newDate = [stringToDateFormatter dateFromString:date];
    
//    struct tm  sometime;
//    const char *formatString = "%Y-%m-%d'T'%H:%M:%S%Z";
//    (void) strptime_l(date, formatString, &sometime, NULL);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    
    NSString *string = [formatter stringFromDate:newDate];
    
    if (string == nil)
    {
        return @"";
    }
    else
    {
        return string;
    }
}

#pragma mark - Vital-signs-related methods
-(NSUInteger) numberOfVitalSignsRowsExcludingHeader {
    if ([self isVitalSignsAvailable]) {
        NSUInteger result = [self latestVitalSigns].observations.count;
        if (self.vitalSigns.count > 1) {
            result++;
        }
        return result;
    } else {
        return 1;
    }
}
-(MRSVitalSigns*) latestVitalSigns {
    return [self isVitalSignsAvailable] ? [self.vitalSigns objectAtIndex:0] : nil;
}
-(BOOL) isVitalSignsLoaded {
    return self.vitalSigns != nil;
}
-(BOOL) isVitalSignsAvailable {
    return self.vitalSigns.count > 0;
}

#pragma mark - UITableViewController methods
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        return 44;
    }
    
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    NSString *detail = cell.detailTextLabel.text;
    
    CGRect bounding = [detail boundingRectWithSize:CGSizeMake(self.view.frame.size.width, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : cell.detailTextLabel.font} context:nil];
    return MAX(44,bounding.size.height+10);
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return (self.isShowingActions) ? 3 : 1;
    }
    else if (section == 1)
    {
        return self.information.count;
    }
    else if (section == 2)
    {
        return self.vitalSignsExpanded ? [self numberOfVitalSignsRowsExcludingHeader] + 1 : 1;
    }
    else if (section == 3)
    {
        return 2;
    }
    else
    {
        return 1;
    }
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (!self.isShowingActions)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"showActions"];
            
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"showActions"];
            }
            
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = @"Actions...";
            cell.textLabel.textColor = self.view.tintColor;
            
            return cell;
        }
        if (indexPath.row == 2)
        {
            UITableViewCell *saveToCoreDataCell = [tableView dequeueReusableCellWithIdentifier:@"coredata"];
            if (!saveToCoreDataCell)
            {
                saveToCoreDataCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"coredata"];
            }
            
            if (self.patient.isInCoreData)
            {
                saveToCoreDataCell.textLabel.text = @"Update Offline Record";
            }
            else
            {
                saveToCoreDataCell.textLabel.text = @"Save for Offline Use";
            }
            saveToCoreDataCell.textLabel.textAlignment = NSTextAlignmentCenter;
            saveToCoreDataCell.textLabel.textColor = self.view.tintColor;
            
            return saveToCoreDataCell;
        }

        if (indexPath.row == 0)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"addVisitNoteCell"];
            
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"addVisitNoteCell"];
            }
            
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = self.view.tintColor;
            cell.textLabel.text = @"Add Visit Note...";
            
            return cell;
        }
        UITableViewCell *actionCell = [tableView dequeueReusableCellWithIdentifier:@"actionCell"];
        
        if (!actionCell)
        {
            actionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"actionCell"];
        }
        
        actionCell.textLabel.text = @"Capture Vitals...";
        actionCell.textLabel.textAlignment = NSTextAlignmentCenter;
        actionCell.textLabel.textColor = self.view.tintColor;
        
        return actionCell;
    }
    if (indexPath.section == 3)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"countCell"];
        
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"countCell"];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if (indexPath.row == 0)
        {
            cell.textLabel.text = @"Visits";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.visits.count];
            cell.imageView.image = [UIImage imageNamed:@"openmrs_icon_visit.png"];
            
        }
        else if (indexPath.row == 1)
        {
            cell.textLabel.text = @"Encounters";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.encounters.count];
            
        }
        return cell;
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"vitalHeaderCell"];
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"vitalHeaderCell"];
        }

        cell.textLabel.text = @"Vital Signs";
        cell.imageView.image = [UIImage imageNamed:self.vitalSignsExpanded ?  @"openmrs_icon_caretdown.png" :  @"openmrs_icon_caretright.png"];
        
        if ([self isVitalSignsAvailable]) {
            cell.detailTextLabel.text = [self latestVitalSigns].formattedEncounterDatetime;
        }
        
        return cell;
    } else if (indexPath.section == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"vitalSignCell"];
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"vitalSignCell"];
        }

        cell.accessoryType = UITableViewCellAccessoryNone;
        if (!self.isViewLoaded) {
            cell.textLabel.text = @"Loading...";
            cell.detailTextLabel.text = nil;
        } else if (![self isVitalSignsAvailable]) {
            cell.textLabel.text = @"No vital signs recorded";
            cell.detailTextLabel.text = nil;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Date:";
            cell.detailTextLabel.text = [self latestVitalSigns].formattedFullEncounterDatetime;
        } else if (indexPath.row-1 < [self latestVitalSigns].observations.count) {
            MRSObservation* observation = [[self latestVitalSigns].observations objectAtIndex:(indexPath.row-1)];
            cell.textLabel.text = observation.conceptDisplayName;
            cell.detailTextLabel.text = [observation.value stringValue];
        } else {
            cell.textLabel.text = @"More...";
            cell.detailTextLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        return cell;
    } else {
    
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        }
        
        NSString *key = ((NSDictionary *)self.information[indexPath.row]).allKeys[0];
        NSString *value = [self.information[indexPath.row] valueForKey:key];
        
        cell.textLabel.text = key;
        cell.detailTextLabel.text = value;
        cell.detailTextLabel.numberOfLines = 0;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (!self.isShowingActions)
        {
            self.isShowingActions = YES;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            return;
        }
        if (indexPath.row == 2)
        {
            [self.patient saveToCoreData];
            return;
        }
        
        if (indexPath.row == 0)
        {
            AddVisitNoteTableViewController *addVisitNote = [[AddVisitNoteTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            addVisitNote.delegate = self;
            addVisitNote.patient = self.patient;
            addVisitNote.delegate = self;
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:addVisitNote] animated:YES completion:nil];
        }
        else if (indexPath.row == 1)
        {
            CaptureVitalsTableViewController *vitals = [[CaptureVitalsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            vitals.patient = self.patient;
            vitals.delegate = self;
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vitals] animated:YES completion:nil];
        }
    }
    else if (indexPath.section == 2 && indexPath.row == 0)
    {
        BOOL expanded = self.vitalSignsExpanded;
        
        self.vitalSignsExpanded = !self.vitalSignsExpanded;
        
        [self.tableView beginUpdates];
        //        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
        NSUInteger count = [self numberOfVitalSignsRowsExcludingHeader];
        NSMutableArray* paths = [[NSMutableArray alloc] init];
        for (int i = 1; i <= count; i++) {
            [paths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        }
        
        
        if (expanded) {
            [tableView deleteRowsAtIndexPaths:paths
                             withRowAnimation:UITableViewRowAnimationTop];
        } else {
            [tableView insertRowsAtIndexPaths:paths
                             withRowAnimation:UITableViewRowAnimationTop];
        }
        [self.tableView endUpdates];
        
        [self performSelector:@selector(toggleOpenIndicator:) withObject:indexPath afterDelay:0.3];
        
    }
    else if (indexPath.section == 3)
    {
        if (indexPath.row == 1) //encounters row selected
        {
            PatientEncounterListView *encounterList = [[PatientEncounterListView alloc] initWithStyle:UITableViewStyleGrouped];
            encounterList.encounters = self.encounters;
            [self.navigationController pushViewController:encounterList animated:YES];
        }
        else if (indexPath.row == 0) //visits row selected
        {
            PatientVisitListView *visitsList = [[PatientVisitListView alloc] initWithStyle:UITableViewStyleGrouped];
            visitsList.visits = self.visits;
            [self.navigationController pushViewController:visitsList animated:YES];
        }
    }
}

-(void) toggleOpenIndicator:(NSIndexPath*) indexPath {
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}
    
- (void)didAddVisitNoteToPatient:(MRSPatient *)patient
{
    if ([patient.UUID isEqualToString:self.patient.UUID])
    {
        [self updateWithDetailedInfo];
    }
}
- (void)didCaptureVitalsForPatient:(MRSPatient *)patient
{
    if ([patient.UUID isEqualToString:self.patient.UUID])
    {
        [self updateWithDetailedInfo];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
