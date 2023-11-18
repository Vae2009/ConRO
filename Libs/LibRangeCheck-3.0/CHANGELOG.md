# Lib: RangeCheck-3.0

## [1.0.3](https://github.com/WeakAuras/LibRangeCheck-3.0/tree/1.0.3) (2023-11-17)
[Full Changelog](https://github.com/WeakAuras/LibRangeCheck-3.0/commits/1.0.3) [Previous Releases](https://github.com/WeakAuras/LibRangeCheck-3.0/releases)

- Fix error when checker list is empty  
- Apply CombatLockDown restrictions only on Retail  
- Check for InCombatLockDown() to decide which checkers can be used  
    In an hotfix CheckInteractDistance and IsItemInRange were made  
    protected in combat.  
    Blizzard in their incompetence somehow managed to not release that  
    in 10.2 as planned and didn't tell us about the plan to change it in 10.2.  
    And didn't tell us in advance of the hotfix releasing, nor could they  
    clarify whether the hotfix was intentionally for several hours after the  
    hotfix was released.  
- More metadata updates  
- Add packager  
- Apply formatting  
- Add metadata and config files  
- initial import  
- Initial commit  