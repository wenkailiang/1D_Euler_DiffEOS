c
c
c =========================================================
       subroutine qinit(meqn,mbc,mx,xlower,dx,q,maux,aux)
c =========================================================
c
c     # Set initial conditions for q.
c     # Smooth entropy wave hitting a shock
c
c
      implicit double precision (a-h,o-z)
      dimension q(meqn,1-mbc:mx+mbc)
      dimension p(1-mbc:mx+mbc)
      dimension aux(maux,1-mbc:mx+mbc)
      dimension dist(500), pressure(500)
      
      ! For initial conditions
      integer mx_ic, my_ic
      real density(800), momx(800), momy(800), ene(800)
      
      common /param/ gammagas, gammaplas, gammawat
      common /param/ pinfgas,pinfplas,pinfwat
      common /param/ omegas,omeplas,omewat
      common /param/ rhog,rhop,rhow
c
c     
      ! Open file for pressure Gauge plot
      open (22,file="a-pgauge.dat",action="write",
     & status="replace")
      open (23,file="a-pIC.dat",action="read",status="old")
!       open (24,file="a-IC_from3D.dat",action="read",status="old")
!       
      ! Read pressure data from file
      do i=1,500
        read(23,*) dist(i), pressure(i)
        !print*, dist(i),pressure(i)
      enddo
      
!       read(24,*) g_num
!       read(24,*) AMR_lvl
!       read(24,*) mx_ic
!       read(24,*) my_ic
!       read(24,*) xlow
!       read(24,*) ylow
!       read(24,*) ddx
!       read(24,*) ddy
!       
!       do i=1,mx_ic 
!         read(24,*) density(i), momx(i), momy(i), ene(i)
!       end do

      ! Write initial conditions
      rhog = 1.0 !kg/m^3
      rhop = 1050.0 !kg/m^3
      rhow = 1000.0 !kg/m^3
      p0 = 101325.0 !
      p = p0
      c0 = sqrt(gammagas*p0/rhog) 
      len_amp = 1.0 !2.0! Amplification factor for length
      amp_amp = 1.0 !8.3 ! Amplification factor for amplitude to get right sockwave before transwell
      Egas0 = p0/(gammagas - 1.d0)  
      q(1,0) = density(1)
      q(2,0) = momx(1)
      q(3,0) = ene(1)
      do 150 i=1,mx
         xcell = xlower + (i-0.5d0)*dx
!          q(1,i) = density(i)
!          q(2,i) = momx(i)
!          q(3,i) = ene(i)

         ! Look for correct value for pressure in data file
         ddx = (dist(101) - dist(100))/len_amp
         do j=1,500
          dist2 = (dist(j)/len_amp - 16.0) 
          if (abs(dist2 - xcell) <  ddx/2) then
            if (pressure(j) > 0) then
              p(i) = amp_amp*6894.75729*pressure(j) + p0
            else 
              p(i) = 6894.75729*pressure(j) + p0
            end if
            
!           exit
          end if
         end do

         if (aux(1,i) == gammagas) then
          q(1,i) = rhog*(p(i)/p0)**(1/gammagas) !+ 5.0d0*dexp(-200.d0*(xcell+1.0)**2)
          q(2,i) = (2/(gammagas - 1.0))*(-c0 + 
     & sqrt(gammagas*p(i)/q(1,i)))
!          q(2,i) = 0.d0
          q(3,i) = p(i)/(aux(1,i) - 1.0) + q(2,i)**2/(2.0*q(1,i))
         else if (aux(1,i) == gammaplas) then
          q(1,i) = rhop
          q(2,i) = 0.0
          ! make sure pressure jump is zero across interface using SGEOS
          q(3,i) = gammaplas*pinfplas - gammagas*pinfgas
          q(3,i) = q(3,i) + Egas0*(gammagas - 1.d0)/(1.d0 - omegas*rhog)
          q(3,i) = q(3,i)*(1.d0 - omeplas*rhop)/(gammaplas - 1.d0)
          Eplas0 = 1.0*q(3,i) ! Needed to compute energy in water state 
         else
          q(1,i) = rhow
          q(2,i) = 0.0
!           ! Make sure jump in pressure is zero again
!           q(3,i) = -gammaplas*pinfplas + gammawat*pinfwat
!           q(3,i) = q(3,i)+Eplas0*(gammaplas - 1.d0)/(1.d0 - omewat*rhow)
!           q(3,i) = q(3,i)*(1.d0 - omeplas*rhop)/(gammawat - 1.d0)
          
          ! Make sure jump in pressure is zero again (from air to water interface)
          q(3,i) = -gammagas*pinfgas + gammawat*pinfwat
          q(3,i) = q(3,i)+Egas0*(gammagas - 1.d0)/(1.d0 - omewat*rhow)
          q(3,i) = q(3,i)*(1.d0 - omegas*rhog)/(gammawat - 1.d0)
         end if
         
  150    continue

!       q(1,1) = q(1,2)
!       q(2,1) = q(2,2)
!       q(3,1) = q(3,2)
!       q(1,mx) = q(1,mx-1)
!       q(2,mx) = q(2,mx-1)
!       q(3,mx) = q(3,mx-1)
c
      return
      end

